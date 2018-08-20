//
//  BKDecision.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/8/18.
//

import Foundation

internal class BKDecision: NSObject, BKData {

    static var neutral: String = "neutralResponse"

    class func neutral(for actionID: String) -> BKDecision {
        return BKDecision(neutral, BKRefreshCartridge.neutralCartridgeId, actionID)
    }

    let name: String
    let cartridgeID: String
    let actionID: String

    init(_ name: String,
         _ cartridgeID: String,
         _ actionID: String) {
        self.name = name
        self.cartridgeID = cartridgeID
        self.actionID = actionID
    }

    public required convenience init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: "name") as? String,
            let cartridgeID = aDecoder.decodeObject(forKey: "cartridgeID") as? String,
            let actionID = aDecoder.decodeObject(forKey: "actionID") as? String else {
                return nil
        }
        self.init(name,
                  cartridgeID,
                  actionID)
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(cartridgeID, forKey: "cartridgeID")
        aCoder.encode(actionID, forKey: "actionID")
    }
}
