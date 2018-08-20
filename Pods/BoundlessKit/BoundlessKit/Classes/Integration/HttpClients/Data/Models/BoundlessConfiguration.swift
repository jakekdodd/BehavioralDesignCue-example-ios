//
//  BoundlessConfiguration.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/10/18.
//

import Foundation

internal struct BoundlessConfiguration {

    let configID: String?

    let integrationMethod: String
    let reinforcementEnabled: Bool
    let reportBatchSize: Int
    let triggerEnabled: Bool
    let trackingEnabled: Bool
    let trackBatchSize: Int

    let locationObservations: Bool
    let applicationState: Bool
    let applicationViews: Bool

    let consoleLoggingEnabled: Bool

    init(configID: String? = nil,
         integrationMethod: String = "manual",
         reinforcementEnabled: Bool = true,
         reportBatchSize: Int = 10,
         triggerEnabled: Bool = false,
         trackingEnabled: Bool = true,
         trackBatchSize: Int = 10,
         locationObservations: Bool = false,
         applicationState: Bool = false,
         applicationViews: Bool = false,
         consoleLoggingEnabled: Bool = true
        ) {
        self.configID = configID
        self.integrationMethod = integrationMethod
        self.reinforcementEnabled = reinforcementEnabled
        self.reportBatchSize = reportBatchSize
        self.triggerEnabled = triggerEnabled
        self.trackingEnabled = trackingEnabled
        self.trackBatchSize = trackBatchSize
        self.locationObservations = locationObservations
        self.applicationState = applicationState
        self.applicationViews = applicationViews
        self.consoleLoggingEnabled = consoleLoggingEnabled
    }
}

extension BoundlessConfiguration {
    func encode() -> Data {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(configID, forKey: "configID")
        archiver.encode(integrationMethod, forKey: "integrationMethod")
        archiver.encode(reinforcementEnabled, forKey: "reinforcementEnabled")
        archiver.encode(reportBatchSize, forKey: "reportBatchSize")
        archiver.encode(triggerEnabled, forKey: "triggerEnabled")
        archiver.encode(trackingEnabled, forKey: "trackingEnabled")
        archiver.encode(trackBatchSize, forKey: "trackBatchSize")
        archiver.encode(locationObservations, forKey: "locationObservations")
        archiver.encode(applicationState, forKey: "applicationState")
        archiver.encode(applicationViews, forKey: "applicationViews")
        archiver.encode(consoleLoggingEnabled, forKey: "consoleLoggingEnabled")
        archiver.finishEncoding()
        return data as Data
    }

    init?(data: Data) {
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        defer {
            unarchiver.finishDecoding()
        }
        guard let configID = unarchiver.decodeObject(forKey: "configID") as? String else { return nil }
        guard let integrationMethod = unarchiver.decodeObject(forKey: "integrationMethod") as? String else { return nil }
        self.init(configID: configID,
                  integrationMethod: integrationMethod,
                  reinforcementEnabled: unarchiver.decodeBool(forKey: "reinforcementEnabled"),
                  reportBatchSize: unarchiver.decodeInteger(forKey: "reportBatchSize"),
                  triggerEnabled: unarchiver.decodeBool(forKey: "triggerEnabled"),
                  trackingEnabled: unarchiver.decodeBool(forKey: "trackingEnabled"),
                  trackBatchSize: unarchiver.decodeInteger(forKey: "trackBatchSize"),
                  locationObservations: unarchiver.decodeBool(forKey: "locationObservations"),
                  applicationState: unarchiver.decodeBool(forKey: "applicationState"),
                  applicationViews: unarchiver.decodeBool(forKey: "applicationViews"),
                  consoleLoggingEnabled: unarchiver.decodeBool(forKey: "consoleLoggingEnabled")
        )
    }
}

extension BoundlessConfiguration {
    static func convert(from dict: [String: Any]) -> BoundlessConfiguration? {
        guard let configID = dict["configID"] as? String? else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let reinforcementEnabled = dict["reinforcementEnabled"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let triggerEnabled = dict["triggerEnabled"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let trackingEnabled = dict["trackingEnabled"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let trackingCapabilities = dict["trackingCapabilities"] as? [String: Any] else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let applicationState = trackingCapabilities["applicationState"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let applicationViews = trackingCapabilities["applicationViews"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let locationObservations = trackingCapabilities["locationObservations"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let batchSize = dict["batchSize"] as? [String: Any] else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let trackBatchSize = batchSize["track"] as? Int else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let reportBatchSize = batchSize["report"] as? Int else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let integrationMethod = dict["integrationMethod"] as? String else { BKLog.debug(error: "Bad parameter"); return nil }
        guard let consoleLoggingEnabled = dict["consoleLoggingEnabled"] as? Bool else { BKLog.debug(error: "Bad parameter"); return nil }

        return BoundlessConfiguration.init(configID: configID,
                                           integrationMethod: integrationMethod,
                                           reinforcementEnabled: reinforcementEnabled,
                                           reportBatchSize: reportBatchSize,
                                           triggerEnabled: triggerEnabled,
                                           trackingEnabled: trackingEnabled,
                                           trackBatchSize: trackBatchSize,
                                           locationObservations: locationObservations,
                                           applicationState: applicationState,
                                           applicationViews: applicationViews,
                                           consoleLoggingEnabled: consoleLoggingEnabled
        )
    }
}
