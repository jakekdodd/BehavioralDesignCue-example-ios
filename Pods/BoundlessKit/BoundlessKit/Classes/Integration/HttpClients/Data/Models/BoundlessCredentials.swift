//
//  BoundlessCredentials.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/10/18.
//

import Foundation

internal struct BoundlessCredentials {

    let clientOS = "iOS"
    let clientOSVersion = UIDevice.current.systemVersion
    let clientSDKVersion = Bundle(for: BoundlessKit.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let clientBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

    let appID: String
    let user: BoundlessUser
    let inProduction: Bool
    let developmentSecret: String
    let productionSecret: String

    init(_ userIdSource: BoundlessUser.IdSource, _ appID: String, _ inProduction: Bool, _ developmentSecret: String, _ productionSecret: String) {
        self.user = BoundlessUser(idSource: userIdSource)
        self.appID = appID
        self.inProduction = inProduction
        self.developmentSecret = developmentSecret
        self.productionSecret = productionSecret
    }

    var json: [String: Any] {
        get {
            return [ "clientOS": clientOS,
                     "clientOSVersion": clientOSVersion,
                     "clientSDKVersion": clientSDKVersion,
                     "clientBuild": clientBuild,
                     "primaryIdentity": user.id ?? "IDUNAVAILABLE",
                     "appId": appID,
                     "secret": inProduction ? productionSecret : developmentSecret,
                     "utc": NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000),
                     "timezoneOffset": NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
            ]
        }
    }
}

extension BoundlessCredentials {
    static func convert(from propertiesDictionary: [String: Any]) -> BoundlessCredentials? {
        guard let appID = propertiesDictionary["appID"] as? String else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let inProduction = propertiesDictionary["inProduction"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let productionSecret = propertiesDictionary["productionSecret"] as? String else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let developmentSecret = propertiesDictionary["developmentSecret"] as? String else { BKLog.debug(error: "Bad parameter"); return nil }
        let userIdSource: BoundlessUser.IdSource = {
            if let idSourceString = propertiesDictionary["userIdSource"] as? String,
                let idSource = BoundlessUser.IdSource(rawValue: idSourceString) {
                return idSource
            } else if BoundlessKeychain.userIdCustom != nil {
                return .custom
            } else {
                return .idfv
            }
        }()

        return BoundlessCredentials(
            userIdSource,
            appID,
            inProduction,
            developmentSecret,
            productionSecret
        )
    }
}
