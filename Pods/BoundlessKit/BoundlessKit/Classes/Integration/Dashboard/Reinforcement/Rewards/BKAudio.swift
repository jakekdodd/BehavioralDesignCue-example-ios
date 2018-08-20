//
//  BKAudio.swift
//  BoundlessKit
//
//  Created by Akash Desai on 11/29/17.
//

import Foundation
import AudioToolbox

internal class BKAudio: NSObject {

    fileprivate static let audioQueue = DelayedSerialQueue(delayAfter: 1, dropCollisions: true)

    class func play(_ systemSoundID: SystemSoundID = 0, vibrate: Bool = false) {
        audioQueue.addOperation {
            if systemSoundID != 0 {
                AudioServicesPlaySystemSound(systemSoundID)
            }
            if vibrate {
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
        }
    }

}
