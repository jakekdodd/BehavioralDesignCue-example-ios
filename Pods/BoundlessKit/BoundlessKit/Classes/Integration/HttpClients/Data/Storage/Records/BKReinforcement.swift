//
//  BKReinforcement.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation

internal class BKReinforcement: NSObject, BKData {

    let name: String
    let cartridgeID: String
    let actionID: String
    var metadata: [String: Any]
    let utc: Int64
    let timezoneOffset: Int64

    convenience init(_ decision: BKDecision,
                     _ metadata: [String: Any] = [:]) {
        self.init(decision.name, decision.cartridgeID, decision.actionID, metadata)
    }

    init(_ name: String,
         _ cartridgeID: String,
         _ actionID: String,
         _ metadata: [String: Any] = [:],
         _ utc: Int64 = Int64( 1000*Date().timeIntervalSince1970 ),
         _ timezoneOffset: Int64 = Int64( 1000*NSTimeZone.default.secondsFromGMT() )) {
        self.name = name
        self.cartridgeID = cartridgeID
        self.actionID = actionID
        self.metadata = metadata
        self.utc = utc
        self.timezoneOffset = timezoneOffset
    }

    public required convenience init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: "name") as? String,
            let cartridgeID = aDecoder.decodeObject(forKey: "cartridgeID") as? String,
            let actionID = aDecoder.decodeObject(forKey: "actionID") as? String,
            let metadata = aDecoder.decodeObject(forKey: "metadata") as? [String: Any] else {
                return nil
        }
        self.init(name,
                  cartridgeID,
                  actionID,
                  metadata,
                  aDecoder.decodeInt64(forKey: "utc"),
                  aDecoder.decodeInt64(forKey: "timezoneOffset"))
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(cartridgeID, forKey: "cartridgeID")
        aCoder.encode(actionID, forKey: "actionID")
        aCoder.encode(metadata, forKey: "metadata")
        aCoder.encode(utc, forKey: "utc")
        aCoder.encode(timezoneOffset, forKey: "timezoneOffset")
    }
}

extension BKReinforcement {
    func toJSONType() -> [String: Any] {
        var jsonObject: [String: Any] = [:]

//        jsonObject["actionID"] = actionID
        jsonObject["reinforcementDecision"] = name
        jsonObject["metadata"] = metadata
        jsonObject["utc"] = NSNumber(value: utc)
        jsonObject["timezoneOffset"] = NSNumber(value: timezoneOffset)

        return jsonObject
    }
}
