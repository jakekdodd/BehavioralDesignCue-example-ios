//
//  BoundlessVersion.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/10/18.
//

import Foundation

internal struct BoundlessVersion {

    let name: String?
    let mappings: [String: [String: Any]]

    internal let database: BKUserDefaults
    internal var trackBatch: BKTrackBatch
    internal var reportBatch: BKReportBatch
    internal var refreshContainer: BKRefreshCartridgeContainer

    init(_ name: String? = nil,
         _ mappings: [String: [String: Any]] = [:],
         database: BKUserDefaults = BKUserDefaults.standard) {
        self.name = name
        self.mappings = mappings
        self.database = database
        self.trackBatch = BKTrackBatch.initWith(database: database, forKey: "trackBatch")
        self.reportBatch = BKReportBatch.initWith(database: database, forKey: "reportBatch")
        self.refreshContainer = BKRefreshCartridgeContainer.initWith(database: database, forKey: "refreshContainer")
    }
}

extension BoundlessVersion {
    init?(data: Data, database: BKUserDefaults) {
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        defer {
            unarchiver.finishDecoding()
        }
        guard let versionID = unarchiver.decodeObject(forKey: "versionID") as? String? else { return nil }
        guard let mappings = unarchiver.decodeObject(forKey: "mappings") as? [String: [String: Any]] else { return nil }
        self.init(versionID, mappings, database: database)
    }

    func encode() -> Data {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(name, forKey: "versionID")
        archiver.encode(mappings, forKey: "mappings")
        archiver.finishEncoding()
        return data as Data
    }
}

extension BoundlessVersion {
    static func convert(from dict: [String: Any], database: BKUserDefaults) -> BoundlessVersion? {
        guard let versionID = dict["versionID"] as? String else { BKLog.debug(error: "Bad parameter"); return nil }
        let mappings = dict["mappings"] as? [String: [String: Any]] ?? [:]

        return BoundlessVersion.init(
            versionID,
            mappings,
            database: database
        )
    }
}
