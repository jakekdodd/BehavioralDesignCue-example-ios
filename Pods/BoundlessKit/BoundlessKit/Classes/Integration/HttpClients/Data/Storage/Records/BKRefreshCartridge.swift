//
//  BKRefreshCartridge.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/12/18.
//

import Foundation

internal class BKRefreshCartridge: NSObject, BKData {

    static let neutralCartridgeId = "CLIENT_NEUTRAL"

    let cartridgeID: String
    let actionID: String
    var decisions: [BKDecision]
    var expirationUTC: Int64
    var desiredMinCountUntilSync: Int

    init(cartridgeID: String,
         actionID: String,
         expirationUTC: Int64 = Int64(1000*Date().timeIntervalSince1970),
         sizeUntilSync: Int = 2,
         decisions: [BKDecision] = []) {
        self.cartridgeID = cartridgeID
        self.actionID = actionID
        self.expirationUTC = expirationUTC
        self.desiredMinCountUntilSync = sizeUntilSync
        self.decisions = decisions
        super.init()
    }

    class func initNeutral(actionID: String) -> BKRefreshCartridge {
        return BKRefreshCartridge(cartridgeID: neutralCartridgeId, actionID: actionID)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        guard
            let cartridgeID = aDecoder.decodeObject(forKey: "cartridgeID") as? String,
            let actionID = aDecoder.decodeObject(forKey: "actionID") as? String,
            let arrayData = aDecoder.decodeObject(forKey: "decisions") as? Data,
            let arrayValues = NSKeyedUnarchiver.unarchiveObject(with: arrayData) as? [BKDecision] else {
                return nil
        }
        let expirationUTC = aDecoder.decodeInt64(forKey: "expirationUTC")
        let desiredMinCountUntilSync = aDecoder.decodeInteger(forKey: "desiredMinCountUntilSync")
        self.init(
            cartridgeID: cartridgeID,
            actionID: actionID,
            expirationUTC: expirationUTC,
            sizeUntilSync: desiredMinCountUntilSync,
            decisions: arrayValues)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(cartridgeID, forKey: "cartridgeID")
        aCoder.encode(actionID, forKey: "actionID")
        aCoder.encode(NSKeyedArchiver.archivedData(withRootObject: decisions), forKey: "decisions")
        aCoder.encode(expirationUTC, forKey: "expirationUTC")
        aCoder.encode(desiredMinCountUntilSync, forKey: "desiredMinCountUntilSync")
    }

    var needsSync: Bool {
        return decisions.count <= desiredMinCountUntilSync || Int64(1000*Date().timeIntervalSince1970) >= expirationUTC
    }
}
