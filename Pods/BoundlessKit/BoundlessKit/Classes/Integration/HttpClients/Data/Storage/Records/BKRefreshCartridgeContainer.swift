//
//  BKRefreshCartridgeContainer.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/12/18.
//

import Foundation

internal class BKRefreshCartridgeContainer: NSObject, BKData, BoundlessAPISynchronizable {

    var enabled = true

    let lock = NSRecursiveLock()
    var storage: BKDatabase.Storage?
    var cartridges = [String: BKRefreshCartridge]()

    init(cartridges: [String: BKRefreshCartridge] = [:]) {
        self.cartridges = cartridges
        super.init()
    }

    class func initWith(database: BKDatabase, forKey key: String) -> BKRefreshCartridgeContainer {
        let container: BKRefreshCartridgeContainer
        if let archived: BKRefreshCartridgeContainer = database.unarchive(key) {
            container = archived
        } else {
            container = BKRefreshCartridgeContainer()
        }
        container.storage = (database, key)
        return container
    }

    required convenience init?(coder aDecoder: NSCoder) {
        guard let dictData = aDecoder.decodeObject(forKey: "cartridges") as? Data,
            let dictValues = NSKeyedUnarchiver.unarchiveObject(with: dictData) as? [String: BKRefreshCartridge] else {
                return nil
        }
        self.init(cartridges: dictValues)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(NSKeyedArchiver.archivedData(withRootObject: self.cartridges), forKey: "cartridges")
    }

    func decision(forActionID actionID: String) -> BKDecision {
        guard enabled else {
            return BKDecision.neutral(for: actionID)
        }

        lock.lock()
        defer { lock.unlock() }

        let cartridge: BKRefreshCartridge = cartridges[actionID] ?? {
            let cartridge = BKRefreshCartridge.initNeutral(actionID: actionID)
            cartridges[actionID] = cartridge
            return cartridge
        }()

        let decision: BKDecision
        if !cartridge.decisions.isEmpty {
            decision = cartridge.decisions.removeFirst()
            save()
            BKLog.print("Cartridge for actionID <\(actionID)> unloaded decision <\(decision.name)>")
        } else {
            decision = BKDecision.neutral(for: actionID)
            BKLog.print("Cartridge for actionID <\(actionID)> is empty! Using default decision <\(decision.name)>")
        }

        return decision
    }

    fileprivate func save() {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.storage?.0.archive(self, forKey: self.storage!.1)
    }

    func clear() {
        self.lock.lock()
        defer { self.lock.unlock() }
        cartridges.removeAll()
        self.storage?.0.archive(self, forKey: self.storage!.1)
    }

    var needsSync: Bool {
        guard enabled else { return false }
        self.lock.lock()
        defer { self.lock.unlock() }
        for cartridge in cartridges.values {
            if cartridge.needsSync { return true }
        }
        return false
    }

    let syncQueue = DispatchQueue(label: "boundless.kit.cartridgecontainer")
    func synchronize(with apiClient: BoundlessAPIClient, successful: @escaping (Bool?) -> Void = {_ in}) {
        guard enabled && apiClient.credentials.user.validId else {
            successful(nil)
            return
        }

        syncQueue.async {
            self.lock.lock()
            defer { self.lock.unlock() }

            var validCartridges = [String: BKRefreshCartridge]()
            for actionID in apiClient.version.mappings.keys {
                validCartridges[actionID] = self.cartridges[actionID] ?? BKRefreshCartridge.initNeutral(actionID: actionID)
            }
            self.cartridges = validCartridges

            let group = DispatchGroup()
            var completeSuccess = true
            for (actionID, cartridge) in self.cartridges where cartridge.needsSync {
                group.enter()
                BKLog.debug("Refreshing cartridge for actionID <\(cartridge.actionID)>...")

                var payload = apiClient.credentials.json
                payload["versionId"] = apiClient.version.name
                payload["actionName"] = cartridge.actionID
                apiClient.post(url: BoundlessAPIEndpoint.refresh.url, jsonObject: payload) { response in
                    var success = false
                    self.lock.lock()
                    defer {
                        self.lock.unlock()
                        group.leave()
                    }
                    if let errors = response?["errors"] as? [String: Any] {
                        BKLog.debug(error: "Cartridge refresh for actionID <\(cartridge.actionID)> failed with error type <\(errors["type"] ?? "nil")> message <\(errors["msg"] ?? "nil")>")
                        return
                    }
                    if let experimentGroup = response?["experimentGroup"] as? String {
                        apiClient.credentials.user.experimentGroup = experimentGroup
                    }
                    if let cartridgeId = response?["cartridgeId"] as? String,
                        let ttl = response?["ttl"] as? Double,
                        let reinforcements = response?["reinforcements"] as? [[String: Any]] {
                        self.cartridges[cartridge.actionID] = BKRefreshCartridge(
                            cartridgeID: cartridgeId,
                            actionID: cartridge.actionID,
                            expirationUTC: Int64( 1000*Date().timeIntervalSince1970 + ttl),
                            decisions: reinforcements.compactMap({$0["reinforcementName"] as? String}).compactMap({BKDecision.init($0, cartridgeId, cartridge.actionID)})
                        )
                        BKLog.debug(confirmed: "Cartridge refresh for actionID <\(cartridge.actionID)> succeeded!")
                        success = true
                    }
                    completeSuccess = completeSuccess && success
                }.start()
            }
            group.notify(queue: .global()) {
                self.save()
                successful(completeSuccess)
            }
        }
    }

}
