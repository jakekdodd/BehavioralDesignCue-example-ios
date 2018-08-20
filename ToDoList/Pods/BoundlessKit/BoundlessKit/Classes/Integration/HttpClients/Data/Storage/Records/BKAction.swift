//
//  BKAction.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation

internal class BKAction: NSObject, BKData {

    let name: String
    var metadata: [String: Any]
    let utc: Int64
    let timezoneOffset: Int64

    init(_ name: String,
         _ metadata: [String: Any] = [:],
         _ utc: Int64 = Int64( 1000*Date().timeIntervalSince1970 ),
         _ timezoneOffset: Int64 = Int64( 1000*NSTimeZone.default.secondsFromGMT() )) {
        self.name = name
        self.utc = utc
        self.metadata = metadata
        self.timezoneOffset = timezoneOffset
    }

    public required convenience init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: "name") as? String,
            let metadata = aDecoder.decodeObject(forKey: "metadata") as? [String: Any] else {
                return nil
        }
        self.init(name,
                  metadata,
                  aDecoder.decodeInt64(forKey: "utc"),
                  aDecoder.decodeInt64(forKey: "timezoneOffset"))
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(metadata, forKey: "metadata")
        aCoder.encode(utc, forKey: "utc")
        aCoder.encode(timezoneOffset, forKey: "timezoneOffset")
    }
}

extension BKAction {
    func toJSONType() -> [String: Any] {
        var jsonObject: [String: Any] = [:]

//        jsonObject["actionID"] = name
        jsonObject["metadata"] = metadata
        jsonObject["utc"] = NSNumber(value: utc)
        jsonObject["timezoneOffset"] = NSNumber(value: timezoneOffset)

        return jsonObject
    }
}
