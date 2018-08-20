//
//  BKTrackBatch.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/11/18.
//

import Foundation

internal class BKTrackBatch: NSObject, BKData, BoundlessAPISynchronizable {

    var enabled = true
    var desiredMaxTimeUntilSync: Int64
    var desiredMaxCountUntilSync: Int

    let lock = NSRecursiveLock()
    var storage: BKDatabase.Storage?
    var actions: [BKAction]

    init(timeUntilSync: Int64 = 86400000,
         sizeUntilSync: Int = 10,
         actions: [BKAction] = []) {
        self.desiredMaxTimeUntilSync = timeUntilSync
        self.desiredMaxCountUntilSync = sizeUntilSync
        self.actions = actions
        super.init()
    }

    class func initWith(database: BKDatabase, forKey key: String) -> BKTrackBatch {
        let batch: BKTrackBatch
        if let archived: BKTrackBatch = database.unarchive(key) {
            batch = archived
        } else {
            batch = BKTrackBatch()
        }
        batch.storage = (database, key)
        return batch
    }

    required convenience init?(coder aDecoder: NSCoder) {
        guard let arrayData = aDecoder.decodeObject(forKey: "actions") as? Data,
            let arrayValues = NSKeyedUnarchiver.unarchiveObject(with: arrayData) as? [BKAction] else {
                return nil
        }
        self.init(timeUntilSync: aDecoder.decodeInt64(forKey: "desiredMaxTimeUntilSync"),
                  sizeUntilSync: aDecoder.decodeInteger(forKey: "desiredMaxCountUntilSync"),
                  actions: arrayValues)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(NSKeyedArchiver.archivedData(withRootObject: actions), forKey: "actions")
        aCoder.encode(desiredMaxTimeUntilSync, forKey: "desiredMaxTimeUntilSync")
        aCoder.encode(desiredMaxCountUntilSync, forKey: "desiredMaxCountUntilSync")
    }

    func add(_ action: BKAction) {
        guard enabled else { return }

        lock.lock()
        defer { lock.unlock() }

        actions.append(action)
        save()

        BKLog.debug(confirmed: "Tracked action #<\(actions.count)>:<\(action.name)>")

        BoundlessContext.getContext { [weak action] contextInfo in
            guard let action = action, !contextInfo.isEmpty else { return }
            for (key, value) in contextInfo {
                action.metadata[key] = value
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
        actions.removeAll()
        self.storage?.0.archive(self, forKey: self.storage!.1)
    }

    var needsSync: Bool {
        guard enabled else { return false }

        lock.lock()
        defer { lock.unlock() }

        if actions.count >= desiredMaxCountUntilSync {
            return true
        } else if let startTime = actions.first?.utc {
            return Int64(1000*NSDate().timeIntervalSince1970) >= (startTime + desiredMaxTimeUntilSync)
        } else {
            return false
        }
    }

    func synchronize(with apiClient: BoundlessAPIClient, successful: @escaping (Bool?) -> Void = {_ in}) {
        guard enabled && apiClient.credentials.user.validId else {
            successful(nil)
            return
        }

        lock.lock()
        defer { lock.unlock() }

        let actionsCopy = actions
        actions.removeAll()
        save()

        guard !actionsCopy.isEmpty else {
            successful(nil)
            return
        }
        BKLog.debug("Sending track batch with \(actionsCopy.count) actions...")

        var trackEvents = [String: [Any]]()
        for event in actionsCopy {
            if trackEvents[event.name] == nil { trackEvents[event.name] = [] }
            trackEvents[event.name]?.append(event.toJSONType())
        }

        var payload = apiClient.credentials.json
        payload["versionId"] = apiClient.version.name
        payload["tracks"] = trackEvents.reduce(into: [[String: Any]](), { (result, args) in
            result.append(["actionName": args.key, "events": args.value])
        })

        apiClient.post(url: BoundlessAPIEndpoint.track.url, jsonObject: payload) { response in
            var success = false
            defer {
                successful(success)
            }

            if let response = response {
                if response.isEmpty {
                    BKLog.debug(confirmed: "Sent track batch!")
                    success = true
                } else if let errors = response["errors"] as? [String: Any] {
                    BKLog.debug(error: "Sending track batch failed with error type <\(errors["type"] ?? "nil")> message <\(errors["msg"] ?? "nil")>")
                    success = false
                }
            }
        }.start()
    }
}
