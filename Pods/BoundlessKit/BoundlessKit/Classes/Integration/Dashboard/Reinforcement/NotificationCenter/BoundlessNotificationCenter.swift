//
//  BoundlessNotificationCenter.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation

internal extension Array where Element == Notification.Name {
    static var visualizerNotifications: [Notification.Name] {
        return [.UIApplicationSendAction]
            + UIViewControllerChildrenDidAppear
            + UICollectionViewControllerChildrenDidSelect
    }

    static var UIViewControllerChildrenDidAppear: [Notification.Name] {
        return forSubclasses(parentClass: UIViewController.self, #selector(UIViewController.viewDidAppear(_:)))
    }

    static var UICollectionViewControllerChildrenDidSelect: [Notification.Name] {
        return forSubclasses(parentClass: UICollectionViewController.self, #selector(UICollectionViewController.collectionView(_:didSelectItemAt:)))
    }

    static func forSubclasses(parentClass: AnyClass, _ selector: Selector) -> [Notification.Name] {
        return (InstanceSelectorHelper.classesInheriting(parentClass) as? [AnyClass])?.compactMap({InstanceSelector($0, selector)?.notificationName}) ?? []
    }

    static func forClassesConforming(to searchProtocol: Protocol, with selector: Selector) -> [Notification.Name] {
        return (InstanceSelectorHelper.classesConforming(searchProtocol) as? [AnyClass])?.compactMap({InstanceSelector.init($0, selector)?.notificationName}) ?? []
    }
}

internal extension Notification.Name {

    static let actionIndicatorTerm = "codeless"

    static let CodelessUIApplicationDidFinishLaunching: String = [actionIndicatorTerm, Notification.Name.UIApplicationDidFinishLaunching.rawValue].joined(separator: "-")

    static let CodelessUIApplicationDidBecomeActive: String = [actionIndicatorTerm, Notification.Name.UIApplicationDidBecomeActive.rawValue].joined(separator: "-")

    static let UIApplicationSendAction: Notification.Name = {
        return InstanceSelector(UIApplication.self, #selector(UIApplication.sendAction(_:to:from:for:)))!.notificationName
    }()

    static let UIViewControllerDidAppear: Notification.Name = {
        return InstanceSelector(UIViewController.self, #selector(UIViewController.viewDidAppear(_:)))!.notificationName
    }()

    static let UIViewControllerDidDisappear: Notification.Name = {
        return InstanceSelector(UIViewController.self, #selector(UIViewController.viewDidDisappear(_:)))!.notificationName
    }()
}

internal class BoundlessNotificationCenter: NotificationCenter {

    static let _default = BoundlessNotificationCenter()
    override public class var `default`: BoundlessNotificationCenter {
        return _default
    }

    fileprivate var posters = [Notification.Name: Poster]()
    fileprivate let queue = DispatchQueue(label: "BoundlessNotificationObserverQueue")

    override public func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?) {
        queue.sync {
            super.addObserver(observer, selector: aSelector, name: aName, object: anObject)
            guard let aName = aName else { return }

            if let aPoster = self.posters[aName] {
                aPoster.addObserver(observer as AnyObject)
//                BKLog.debug("Added observer for instance method:\(aName.rawValue)")
                return
            }

            let aPoster: Poster
            if let instanceSelector = InstanceSelector(aName.rawValue),
                let poster = InstanceSelectorPoster(instanceSelector) {
                aPoster = poster
            } else if aName.rawValue == Notification.Name.CodelessUIApplicationDidFinishLaunching {
                NotificationCenter.default.addObserver(observer, selector: aSelector, name: Notification.Name.UIApplicationDidFinishLaunching, object: anObject)
                return
            } else if aName.rawValue == Notification.Name.CodelessUIApplicationDidBecomeActive {
                NotificationCenter.default.addObserver(observer, selector: aSelector, name: Notification.Name.UIApplicationDidBecomeActive, object: anObject)
                return
            } else {
                return
            }
            self.posters[aName] = aPoster
            aPoster.addObserver(observer as AnyObject)
//            BKLog.debug("Added first observer for instance method:\(aName.rawValue)")

        }
    }

    override public func removeObserver(_ observer: Any) {
        self.removeObserver(observer, name: nil, object: nil)
    }

    override public func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object anObject: Any?) {
        queue.sync {
            if let aName = aName {
                if let poster = self.posters[aName] {
                    poster.removeObserver(observer as AnyObject)
//                    BKLog.debug("Removed observer for notification:\(aName.rawValue)")
                }
            } else {
                for poster in self.posters.values {
                    poster.removeObserver(observer as AnyObject)
                }
            }
            super.removeObserver(observer, name: aName, object: anObject)
        }
    }

    public func removeAllObservers(name aName: NSNotification.Name?) {
        queue.sync {
            if let aName = aName {
                for observer in self.posters[aName]?.removeAllObservers() ?? [] {
                    super.removeObserver(observer, name: aName, object: nil)
                }
            } else {
                for (notification, poster) in self.posters {
                    for observer in poster.removeAllObservers() {
                        super.removeObserver(observer, name: notification, object: nil)
                    }
                }
            }
        }
    }
}

private class Poster: NSObject {

    struct WeakObject {
        weak var value: AnyObject?
        init (value: AnyObject) {
            self.value = value
        }
    }

    var notificationName: Notification.Name? { get { return nil } }
    var observers = [WeakObject]()

    func addObserver(_ observer: AnyObject) {
        observers.append(WeakObject(value: observer))
    }

    func removeObserver(_ observer: AnyObject) {
        observers = observers.filter({$0.value != nil && $0.value !== observer})
    }

    func removeAllObservers() -> [AnyObject] {
        let oldObservers = observers.compactMap({$0.value})
        observers = []
        return oldObservers
    }
}

private class InstanceSelectorPoster: Poster {

    override var notificationName: Notification.Name? { get { return originalSelector.notificationName } }

    let originalSelector: InstanceSelector
    let notificationSelector: InstanceSelector

    init?(_ instanceSelector: InstanceSelector) {
        guard let notificationMethod = InstanceSelectorHelper.createMethod(beforeInstance: instanceSelector.classType, selector: instanceSelector.selector, with: InstanceSelectorPoster.postInstanceSelection),
            let notificationSelector = InstanceSelector(instanceSelector.classType, notificationMethod) else {
            BKLog.debug(error: "Could not create notification method for actionID<\(instanceSelector.notificationName)")
            return nil
        }
            self.originalSelector = instanceSelector
            self.notificationSelector = notificationSelector
            super.init()
    }

    override func addObserver(_ observer: AnyObject) {
        if observers.count == 0 {
            originalSelector.exchange(with: notificationSelector)
        }
        super.addObserver(observer)
    }

    override func removeObserver(_ observer: AnyObject) {
        let oldCount = observers.count
        super.removeObserver(observer)
        if observers.count == 0 && oldCount != 0 {
            originalSelector.exchange(with: notificationSelector)
        }
    }

    override func removeAllObservers() -> [AnyObject] {
        if observers.count != 0 {
            originalSelector.exchange(with: notificationSelector)
        }
        return super.removeAllObservers()
    }

    static var postInstanceSelection: InstanceSelectionBlock {
        return { aClassType, aSelector, aTarget, aSender in
            guard let classType = aClassType,
                let selector = aSelector,
                let instanceSelector = InstanceSelector(classType, selector) else {
                    BKLog.debug("Not posting because <\(String(describing: aClassType))-\(String(describing: aSelector))> is not a valid instance selector")
                    return
            }
            BoundlessNotificationCenter.default.post(name: instanceSelector.notificationName,
                                                     object: nil,
                                                     userInfo: ["classType": classType,
                                                                "selector": selector,
                                                                "sender": aSender as Any,
                                                                "target": aTarget as Any
                                                                ])
        }
//            BKLog.print("Posted instance method notification with name:\(instanceSelector.notificationName.rawValue)")
    }
}

private struct InstanceSelector {
    let classType: AnyClass
    let selector: Selector

    var name: String { return [NSStringFromClass(classType), NSStringFromSelector(selector)].joined(separator: "-") }

    init?(_ classType: AnyClass, _ selector: Selector) {
        guard classType.instancesRespond(to: selector) else {
            BKLog.debug("Could not initialize InstanceSelector because class <\(classType)> does not respond to selector <\(selector)>")
            return nil
        }
        self.classType = classType
        self.selector = selector
    }

    init?(_ name: String) {
        let components = name.components(separatedBy: "-")
        if components.count == 2,
            let classType = NSClassFromString(components[0]) {
            let selector = NSSelectorFromString(components[1])
            self.init(classType, selector)
        } else {
            return nil
        }
    }

    init?(_ notification: Notification.Name) {
        self.init(notification.rawValue)
    }

    var notificationName: Notification.Name {
        return Notification.Name(self.name)
    }

    func exchange(with other: InstanceSelector) {
        InstanceSelectorHelper.injectSelector(other.classType, other.selector, self.classType, self.selector)
    }
}
