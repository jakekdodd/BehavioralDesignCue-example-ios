//
//  BKDatabase.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/8/18.
//

import Foundation

internal protocol BKData: NSCoding {}
internal protocol BKDatabase {
    typealias Storage = (BKDatabase, String)
    func archive<T: BKData>(_ value: T?, forKey key: String)
    func unarchive<T: BKData>(_ key: String) -> T?
}

internal class BKUserDefaults: UserDefaults, BKDatabase {

    private static let suiteName = "boundless.kit.db.1"

    override class var standard: BKUserDefaults {
        get {
            return BKUserDefaults(suiteName: suiteName)!
        }
    }

    func removePersistentDomain() {
        removePersistentDomain(forName: BKUserDefaults.suiteName)
    }

    func archive<T: BKData>(_ value: T?, forKey key: String) {
        if let value = value {
            self.set(NSKeyedArchiver.archivedData(withRootObject: value), forKey: key)
        } else {
            self.set(nil, forKey: key)
        }
    }

    func unarchive<T: BKData>(_ key: String) -> T? {
        if let data = self.object(forKey: key) as? Data,
            let t = NSKeyedUnarchiver.unarchiveObject(with: data) as? T {
            return t
        } else {
            return nil
        }
    }

    var initialBootDate: Date? {
        get {
            let date = object(forKey: "initialBootDate") as? Date
            if date == nil {
                set(Date(), forKey: "initialBootDate")
            }
            return date
        }
    }

}
