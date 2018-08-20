//
//  BKReportBatch.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/12/18.
//

import Foundation

internal class BKReportBatch: NSObject, BKData, BoundlessAPISynchronizable {

    var enabled = true
    var desiredMaxTimeUntilSync: Int64
    var desiredMaxCountUntilSync: Int

    let lock = NSRecursiveLock()
    var storage: BKDatabase.Storage?
    fileprivate var reinforcements: [String: [BKReinforcement]]
    var reinforcementsCount: Int {
        return reinforcements.reduce(0, {$0 + $1.value.count})
    }

    init(timeUntilSync: Int64 = 86400000,
         sizeUntilSync: Int = 10,
         reinforcements: [String: [BKReinforcement]] = [:]) {
        self.desiredMaxTimeUntilSync = timeUntilSync
        self.desiredMaxCountUntilSync = sizeUntilSync
        self.reinforcements = reinforcements
        super.init()
    }

    class func initWith(database: BKDatabase, forKey key: String) -> BKReportBatch {
        let batch: BKReportBatch
        if let archived: BKReportBatch = database.unarchive(key) {
            batch = archived
        } else {
            batch = BKReportBatch()
        }
        batch.storage = (database, key)
        return batch
    }

    required convenience init?(coder aDecoder: NSCoder) {
        guard let dictData = aDecoder.decodeObject(forKey: "reinforcements") as? Data,
            let dictValues = NSKeyedUnarchiver.unarchiveObject(with: dictData) as? [String: [BKReinforcement]] else {
                return nil
        }
        let desiredMaxTimeUntilSync = aDecoder.decodeInt64(forKey: "desiredMaxTimeUntilSync")
        let desiredMaxCountUntilSync = aDecoder.decodeInteger(forKey: "desiredMaxCountUntilSync")
        self.init(timeUntilSync: desiredMaxTimeUntilSync,
                  sizeUntilSync: desiredMaxCountUntilSync,
                  reinforcements: dictValues)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(NSKeyedArchiver.archivedData(withRootObject: reinforcements), forKey: "reinforcements")
        aCoder.encode(desiredMaxTimeUntilSync, forKey: "desiredMaxTimeUntilSync")
        aCoder.encode(desiredMaxCountUntilSync, forKey: "desiredMaxCountUntilSync")
    }

    func add(_ reinforcement: BKReinforcement) {
        guard enabled else { return }

        lock.lock()
        defer { lock.unlock() }

        if reinforcements[reinforcement.actionID] == nil {
            reinforcements[reinforcement.actionID] = []
        }
        reinforcements[reinforcement.actionID]?.append(reinforcement)
        save()

        BKLog.debug(confirmed: "Reported reinforcement #<\(reinforcementsCount)> actionID:<\(reinforcement.actionID)> with reinforcementID:<\(reinforcement.name)>")

        BoundlessContext.getContext { [weak reinforcement] contextInfo in
            guard let reinforcement = reinforcement, !contextInfo.isEmpty else { return }
            for (key, value) in contextInfo {
                reinforcement.metadata[key] = value
            }
            self.save()
        }
    }

    fileprivate func save() {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.storage?.0.archive(self, forKey: self.storage!.1)
    }

    internal func clear() {
        self.lock.lock()
        defer { self.lock.unlock() }
        reinforcements.removeAll()
        self.storage?.0.archive(self, forKey: self.storage!.1)
    }

    var needsSync: Bool {
        guard enabled else { return false }

        lock.lock()
        defer { lock.unlock() }

        if reinforcementsCount >= desiredMaxCountUntilSync {
            return true
        } else {
            let windowBegin = Int64(1000*Date().timeIntervalSince1970) - desiredMaxTimeUntilSync
            for reports in reinforcements.values {
                if let reinforcementTime = reports.first?.utc,
                    windowBegin >= reinforcementTime {
                    return true
                }
            }
        }
        return false
    }

    func synchronize(with apiClient: BoundlessAPIClient, successful: @escaping (Bool?) -> Void = {_ in}) {
        guard enabled && apiClient.credentials.user.validId else {
            successful(nil)
            return
        }

        lock.lock()
        defer { lock.unlock() }

        let reinforcementsCopy = reinforcements
        clear()

        guard !reinforcementsCopy.isEmpty else {
            successful(nil)
            return
        }
        BKLog.debug("Sending report batch with \(reinforcementsCopy.reduce(0, {$0 + $1.value.count})) reinforcements...")

        var reportEvents = [String: [String: [[String: Any]]]]()
        for (actionID, events) in reinforcementsCopy {
            if reportEvents[actionID] == nil { reportEvents[actionID] = [:] }
            for reinforcement in events {
                if reportEvents[actionID]?[reinforcement.cartridgeID] == nil { reportEvents[actionID]?[reinforcement.cartridgeID] = [] }
                reportEvents[actionID]?[reinforcement.cartridgeID]?.append(reinforcement.toJSONType())
            }
        }

        var payload = apiClient.credentials.json
        payload["versionId"] = apiClient.version.name
        payload["reports"] = reportEvents.reduce(into: [[[String: Any]]]()) { (result, args) in
            let (key, value) = args
            result.append(value.map {["actionName": key, "cartridgeId": $0.key, "events": $0.value]})
            }.flatMap({$0})

        apiClient.post(url: BoundlessAPIEndpoint.report.url, jsonObject: payload) { response in
            var success = false
            defer {
                successful(success)
            }

            if let response = response {
                if response.isEmpty {
                    BKLog.debug(confirmed: "Sent report batch!")
                    success = true
                } else if let errors = response["errors"] as? [String: Any] {
                    BKLog.debug(error: "Sending report batch failed with error type <\(errors["type"] ?? "nil")> message <\(errors["msg"] ?? "nil")>")
                    success = false
                }
            }
        }.start()
    }
}
