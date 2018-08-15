//
//  AppDelegate.swift
//  BehavioralDesignCue
//
//  Created by cuddergambino on 08/14/2018.
//  Copyright (c) 2018 cuddergambino. All rights reserved.
//

import UIKit
import UserNotifications
import BehavioralDesignCue


/// This example app is aware of what cued the user to open the app. Using BDCue, we set the cue source
/// and modify the UI accordingly. In this example app the UI is simply modified to display the source,
/// but can be further implemented to modify rewards or messages based on cues.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    fileprivate (set) var cue: BDCue? { didSet { onCueChange(oldValue, cue) } }
    
    // MARK: - Initial App Open
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // The user could have launched the app for many reasons.
        // We catch what we can here, and the rest in other methods related to the UIApplication lifecycle
        if #available(iOS 9.0, *), launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] != nil {
            cue = BDCue(source: .internal(.shortcut))
        } else if launchOptions?[UIApplicationLaunchOptionsKey.sourceApplication] != nil || launchOptions?[UIApplicationLaunchOptionsKey.url] != nil {
            cue = BDCue(source: .external(.deepLink))
        } else if launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] != nil || launchOptions?[UIApplicationLaunchOptionsKey.localNotification] != nil {
            cue = BDCue(source: .synthetic(.notification))
        }
        
        customLaunchImplementation(application, didFinishLaunchingWithOptions: launchOptions)
        
        return true
    }
    
    // MARK: - App Open from Shortcut
    
    @available(iOS 9.0, *)
    public func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        // When a user opens your app from a shortcut
        if cue == nil {
            cue = BDCue(source: .internal(.shortcut))
        }
        
        customShortcutImplementation(application, performActionFor: shortcutItem, completionHandler: completionHandler)
        
    }
    
    // MARK: - App Open from Deep Link
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // When a user clicks a deep link that opens your app
        if cue == nil {
            cue = BDCue(source: .external(.deepLink))
        }
        
        customDeepLinkImplementation(app, open: url, options: options)
        
        return true
    }
    
    // MARK: - App Open from Notifications
    
    // MARK: Notifications for iOS >= 10.0
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // When the user opens your app from clicking a notification
        if cue == nil {
            cue = BDCue(source: .synthetic(.notification))
        }
        
        // custom implementation
        
        completionHandler()
    }
    
    // MARK: Notifications for iOS < 10.0
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // When the user opens your app from clicking a remote notification
        if cue == nil {
            cue = BDCue(source: .synthetic(.notification))
        }
        
        // custom implementation
        
        completionHandler(.newData)
    }
    
    public func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        // When the user opens your app from clicking a local notification
        if cue == nil {
            cue = BDCue(source: .synthetic(.notification))
        }
        
        // custom implementation
        
    }
    
    // MARK: - App Open for Default
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        // If none of the other cue types have been set, then the user must've tapped open the app from Spotlight, Springboard, or from the App Switcher which are all internal cues
        if cue == nil {
            cue = BDCue(source: .internal(.default))
        }
        
        // custom implementation
        
    }
    
    // MARK: - App Close
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        // Clear the cue so a new one can be set
        cue = nil
        
        // custom implementation
        
    }
    
}

// MARK: - Custom Implementations

extension AppDelegate {
    
    public func onCueChange(_ oldValue: BDCue?, _ cue: BDCue?) {
        // Make any UI changes based on cue changes
        // In this demo, we log cue changes to be displayed on screen
        Helper.shared.appendLog("[\(Date().friendly)]\t📲 Cue: <\(cue?.source.description ?? "nil")>")
    }
    
    public func customLaunchImplementation(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) {
        Helper.shared.appendLog("Launch options: \(launchOptions as AnyObject)")
        
        // These functions are just for configuring the example app
        if #available(iOS 9.0, *) {
            // Register shortcuts
            UIApplicationShortcutItem.registerShortcuts()
        }
        if #available(iOS 10.0, *) {
            // Set the AppDelegate as NotificationCenter delegate. Needed to capture opens caused by notifications.
            UNUserNotificationCenter.current().delegate = self
        }
    }
    
    @available(iOS 9.0, *)
    public func customShortcutImplementation(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        // This is a basic example of using shortcut actions
        // Displays the view controller for the month specified by the shortcut
        if let shortcutType = ShortcutType(rawValue: shortcutItem.localizedTitle) {
            (window!.rootViewController as! RootViewController).jumpToPageFor(shortcutType.rawValue)
            completionHandler(true)
        } else {
            completionHandler(false)
        }
    }
    
    public func customDeepLinkImplementation(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) {
        // This is a basic example of using deep links
        // Displays the view controller for the month specified by the url
        if let host = url.host {
            (window!.rootViewController as! RootViewController).jumpToPageFor(host)
        }
    }
    
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // The function and the following line is needed to display the notification when the app is in the foreground for demonstration purposes
        completionHandler([.alert, .sound])
    }
    
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Remote notification token:\(deviceToken.encodedAPNSTokenString())")
    }
    
}

