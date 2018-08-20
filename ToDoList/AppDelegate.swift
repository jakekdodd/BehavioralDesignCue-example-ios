//
//  AppDelegate.swift
//
//  Created by cuddergambino on 08/14/2018.
//  Copyright (c) 2018 cuddergambino. All rights reserved.
//

import UIKit
import UserNotifications
import BoundlessKit

/// This example app is aware of what cued the user to open the app.
/// Using AppOpenAction, we know the app open action cue and display a reward accordingly.
///
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    fileprivate (set) var appOpenAction: AppOpenAction? { didSet { onAppOpen(appOpenAction) } }

    // MARK: - Initial App Open

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil) -> Bool {
        // The user could have launched the app for many reasons.
        // We catch what we can here, and the rest in other methods related to the UIApplication lifecycle

        switch launchOptions {
        case _ where launchOptions?[UIApplicationLaunchOptionsKey.sourceApplication] != nil,
             _ where launchOptions?[UIApplicationLaunchOptionsKey.url] != nil:
            appOpenAction = AppOpenAction(source: .deepLink)

        case _ where launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] != nil,
             _ where launchOptions?[UIApplicationLaunchOptionsKey.localNotification] != nil:
            appOpenAction = AppOpenAction(source: .notification)

        default:
            if #available(iOS 9.0, *), launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] != nil {
                appOpenAction = AppOpenAction(source: .shortcut)
            }
        }

        customLaunchImplementation(application, didFinishLaunchingWithOptions: launchOptions)

        return true
    }

    // MARK: - App Open from Shortcut

    @available(iOS 9.0, *)
    public func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        // When a user opens your app from a shortcut
        if appOpenAction == nil {
            appOpenAction = AppOpenAction(source: .shortcut)
        }

        customShortcutImplementation(application, performActionFor: shortcutItem, completionHandler: completionHandler)

    }

    // MARK: - App Open from Deep Link

    public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
        // When a user clicks a deep link that opens your app
        if appOpenAction == nil {
            appOpenAction = AppOpenAction(source: .deepLink)
        }

        customDeepLinkImplementation(app, open: url, options: options)

        return true
    }

    // MARK: - App Open from Notifications

    // MARK: Notifications for iOS >= 10.0
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // When the user opens your app from clicking a notification
        if appOpenAction == nil {
            appOpenAction = AppOpenAction(source: .notification)
        }

        // custom implementation

        completionHandler()
    }

    // MARK: Notifications for iOS < 10.0
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // When the user opens your app from clicking a remote notification
        if appOpenAction == nil {
            appOpenAction = AppOpenAction(source: .notification)
        }

        // custom implementation

        completionHandler(.newData)
    }

    public func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        // When the user opens your app from clicking a local notification
        if appOpenAction == nil {
            appOpenAction = AppOpenAction(source: .notification)
        }

        // custom implementation

    }

    // MARK: - App Open for Default

    public func applicationDidBecomeActive(_ application: UIApplication) {
        // If none of the other app open actions have been set,
        // then the user must've tapped open the app from
        // Spotlight, Springboard, or from the App Switcher which are all internal cues
        if appOpenAction == nil {
            appOpenAction = AppOpenAction(source: .default)
        }

        // custom implementation

    }

    // MARK: - App Close

    public func applicationDidEnterBackground(_ application: UIApplication) {
        // Clear the action so a new one can be set
        appOpenAction = nil

        // custom implementation

    }

}

// MARK: - Custom Implementations

extension AppDelegate {

    public func onAppOpen(_ action: AppOpenAction?) {
        // Show a reward based on the action cue
        // In this demo, we log cue changes to be displayed on screen and show different rewards for each cue category

        if let appOpenAction = appOpenAction {
            Helper.shared.appendLog("[\(Date().friendly)]\t📲 App Open Cue: <\(appOpenAction.cue)>")
            DispatchQueue.main.async {
                switch appOpenAction.cue {

                case .internal:
                    self.window?.showConfetti()

                case .external:
                    break

                case .synthetic:
                    self.window?.showSheen()

                }
            }
        } else {
            Helper.shared.appendLog("[\(Date().friendly)]\t📱 App closed")
        }
    }

    public func customLaunchImplementation(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil) {
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
        if let shortcutType = ShortcutType(rawValue: shortcutItem.localizedTitle),
            let rootViewController = window?.rootViewController as? RootViewController {
            rootViewController.jumpToPageFor(shortcutType.rawValue)
            completionHandler(true)
        } else {
            completionHandler(false)
        }
    }

    public func customDeepLinkImplementation(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) {
        // This is a basic example of using deep links
        // Displays the view controller for the month specified by the url
        if let host = url.host,
            let rootViewController = window?.rootViewController as? RootViewController {
            rootViewController.jumpToPageFor(host)
        }
    }

    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // The function and the following line is needed to display the notification
        // when the app is in the foreground for demonstration purposes
        completionHandler([.alert, .sound])
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Remote notification token:\(deviceToken.encodedAPNSTokenString())")
    }

}
