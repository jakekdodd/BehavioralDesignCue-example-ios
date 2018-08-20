//
//  Reinforcer.swift
//  BoundlessKit
//
//  Created by Akash Desai on 5/2/18.
//

import Foundation

internal class Reinforcer: NSObject {

    enum ScheduleSetting {
        case reinforcement, random
    }

    static var scheduleSetting: ScheduleSetting = .reinforcement

    let actionID: String
    var reinforcementIDs: [String]

    init(forActionID: String, withReinforcementIDs: [String] = []) {
        self.actionID = forActionID
        self.reinforcementIDs = withReinforcementIDs
    }

    convenience init(copy: Reinforcer) {
        self.init(forActionID: copy.actionID, withReinforcementIDs: copy.reinforcementIDs)
    }
}
