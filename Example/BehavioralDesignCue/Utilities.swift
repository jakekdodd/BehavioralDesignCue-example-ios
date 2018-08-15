//
//  Utilities.swift
//  BehavioralDesignCue
//
//  Created by Akash Desai on 8/6/18.
//  Copyright © 2018 Boundless Mind. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

// MARK: - Shortcut Actions

enum ShortcutType: String {
    case march = "March"
    case may = "May"
}

@available(iOS 9.0, *)
public extension UIApplicationShortcutItem {
    public static func registerShortcuts() {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(
                type: "alert",
                localizedTitle: ShortcutType.march.rawValue,
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(templateImageName: "Alert Icon"),
                userInfo: nil
            ), UIApplicationShortcutItem(
                type: "messages",
                localizedTitle: ShortcutType.may.rawValue,
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(templateImageName: "Messenger Icon"),
                userInfo: nil)
        ]
    }
}

// MARK: - Notifications

@available(iOS 10.0, *)
public extension UNUserNotificationCenter {
    public func scheduleNotification(identifier: String, body: String, time: Double = 1) {
        let content =  UNMutableNotificationContent()
        content.body = body
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: time, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
            if (error != nil) {
                print(error!)
            } else {
                print("Success! ID:\(identifier), Message:\(body), Time:\(trigger.timeInterval.magnitude) seconds")
            }
        }
    }
    
    public func requestPermission(remoteRegistration: Bool = true, completion: ((Bool) -> Void)? = nil) {
        getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.requestAuthorization(options: [.alert, .sound]) { granted, error in
                    if granted && remoteRegistration {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                    completion?(granted)
                }
                
            case .authorized:
                completion?(true)
                
            case .denied:
                completion?(false)
            }
        }
    }
}

public extension Data {
    public func encodedAPNSTokenString() -> String {
        return self.map({String(format: "%02.2hhx", $0)}).joined()
    }
}

// MARK: - External URL Scheme

public extension Bundle {
    var externalURLScheme: String? {
        guard let urlTypes = infoDictionary?["CFBundleURLTypes"] as? [AnyObject],
            let urlTypeDictionary = urlTypes.first as? [String: AnyObject],
            let urlSchemes = urlTypeDictionary["CFBundleURLSchemes"] as? [AnyObject],
            let externalURLScheme = urlSchemes.first as? String else {
                return nil
        }
        
        return externalURLScheme
    }
}

// MARK: - Date

extension Date {
    var friendly: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm:ss a"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: self)
    }
}
