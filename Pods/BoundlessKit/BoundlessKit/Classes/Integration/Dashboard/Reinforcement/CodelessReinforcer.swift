//
//  CodelessReinforcer.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation

internal class CodelessReinforcer: Reinforcer {

    var codelessReinforcements = [String: CodelessReinforcement?]()
    override var reinforcementIDs: [String] {
        get {
            return Array(codelessReinforcements.keys)
        }
        set {
            var newReinforcements = [String: CodelessReinforcement?]()
            for id in newValue {
                if let cur = codelessReinforcements[id] {
                    newReinforcements[id] = cur
                } else {
                    newReinforcements[id] = nil as CodelessReinforcement?
                }
            }
            codelessReinforcements = newReinforcements
        }
    }

    @objc
    func receive(notification: Notification) {
//        BKLog.print("Action peformed with actionID <\(actionID)>")
        let target = notification.userInfo?["target"] as? NSObject ?? UIWindow.topWindow ?? NSObject()
        let sender = notification.userInfo?["sender"] as AnyObject?

        switch Reinforcer.scheduleSetting {
        case .reinforcement:
            BoundlessKit.shared.reinforce(actionID: actionID) { reinforcementID in
                BKLog.debug("Showing codeless reinforcementID <\(reinforcementID)> for actionID <\(self.actionID)>...")
                self.codelessReinforcements[reinforcementID]??.show(targetInstance: target, senderInstance: sender)
            }
        case .random:
            guard let randomReinforcement = Array(self.codelessReinforcements.values).randomElement else {
                BKLog.debug(error: "No codeless reinforcement for actionID <\(actionID)>")
                return
            }
            BKLog.debug("Showing random codeless reinforcement <\(String(describing: randomReinforcement?.primitive))> for actionID <\(actionID)>...")
            randomReinforcement?.show(targetInstance: target, senderInstance: sender)
        }
    }

}
