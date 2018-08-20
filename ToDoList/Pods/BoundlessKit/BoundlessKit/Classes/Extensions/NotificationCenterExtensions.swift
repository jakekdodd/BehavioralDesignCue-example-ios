//
//  NotificationCenterExtensions.swift
//  
//
//  Created by Akash Desai on 5/7/18.
//

import Foundation

internal extension NotificationCenter {
    func addObserver(_ observer: Any, selector aSelector: Selector, names someNames: [NSNotification.Name], object anObject: Any?) {
        for aName in someNames {
            self.addObserver(observer, selector: aSelector, name: aName, object: anObject)
        }
    }

    func removeObserver(_ observer: Any, names someNames: [NSNotification.Name], object anObject: Any?) {
        for aName in someNames {
            self.removeObserver(observer, name: aName, object: anObject)
        }
    }
}
