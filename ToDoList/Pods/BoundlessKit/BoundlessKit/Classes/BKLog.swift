//
//  BKLog.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/14/18.
//

import Foundation

@objc open class BKLogPreferences: NSObject {
    @objc open var printEnabled = true
    @objc open var debugEnabled = false
//    @objc open var debugEnabled = true
}

@objc open class BKLog: NSObject {

    @objc open static var preferences = BKLogPreferences()

    /// This function prints to the console if preferences.printEnabled is true
    ///
    /// - parameters:
    ///     - message: The debug message.
    ///     - filePath: Used to get filename of bug. Do not use this parameter. Defaults to #file.
    ///     - function: Used to get function name of bug. Do not use this parameter. Defaults to #function.
    ///     - line: Used to get the line of bug. Do not use this parameter. Defaults to #line.
    ///
    @objc open class func print(_ message: String, filePath: String = #file, function: String =  #function, line: Int = #line) {
        guard preferences.printEnabled else { return }
        var functionSignature: String = function
        if let parameterNames = functionSignature.range(of: "\\((.*?)\\)", options: .regularExpression) {
            functionSignature.replaceSubrange(parameterNames, with: "()")
        }
        let fileName = NSString(string: filePath).lastPathComponent
        Swift.print("[\(fileName):\(line):\(functionSignature)] - \(message)")
    }

    /// This function prints debug messages to the console if preferences.printEnabled and preferences.debugEnabled are true
    ///
    /// - parameters:
    ///     - message: The debug message.
    ///     - filePath: Used to get filename of bug. Do not use this parameter. Defaults to #file.
    ///     - function: Used to get function name of bug. Do not use this parameter. Defaults to #function.
    ///     - line: Used to get the line of bug. Do not use this parameter. Defaults to #line.
    ///
    @objc open class func debug(_ message: String, filePath: String = #file, function: String =  #function, line: Int = #line) {
        guard preferences.printEnabled && preferences.debugEnabled else { return }
        var functionSignature: String = function
        if let parameterNames = functionSignature.range(of: "\\((.*?)\\)", options: .regularExpression) {
            functionSignature.replaceSubrange(parameterNames, with: "()")
        }
        let fileName = NSString(string: filePath).lastPathComponent
        Swift.print("[\(fileName):\(line):\(functionSignature)] - \(message)")
    }

    /// This function prints confirmation messages to the console if preferences.printEnabled and preferences.debugEnabled are true
    ///
    /// - parameters:
    ///     - message: The confirmation message.
    ///     - filePath: Used to get filename. Do not use this parameter. Defaults to #file.
    ///     - function: Used to get function name. Do not use this parameter. Defaults to #function.
    ///     - line: Used to get the line. Do not use this parameter. Defaults to #line.
    ///
    @objc open class func debug(confirmed message: String, filePath: String = #file, function: String =  #function, line: Int = #line) {
        guard preferences.printEnabled && preferences.debugEnabled else { return }
        var functionSignature: String = function
        if let parameterNames = functionSignature.range(of: "\\((.*?)\\)", options: .regularExpression) {
            functionSignature.replaceSubrange(parameterNames, with: "()")
        }
        let fileName = NSString(string: filePath).lastPathComponent
        Swift.print("[\(fileName):\(line):\(functionSignature)] - ✅ \(message)")
    }

    /// This function prints error messages to the console if preferences.printEnabled and preferences.debugEnabled are true
    ///
    /// - parameters:
    ///     - message: The debug message.
    ///     - visual: If true, also displays an OK alert.
    ///     - filePath: Used to get filename of bug. Do not use this parameter. Defaults to #file.
    ///     - function: Used to get function name of bug. Do not use this parameter. Defaults to #function.
    ///     - line: Used to get the line of bug. Do not use this parameter. Defaults to #line.
    ///
    @objc open class func debug(error message: String, visual: Bool = false, filePath: String = #file, function: String =  #function, line: Int = #line) {
        guard preferences.printEnabled && preferences.debugEnabled else { return }
        var functionSignature: String = function
        if let parameterNames = functionSignature.range(of: "\\((.*?)\\)", options: .regularExpression) {
            functionSignature.replaceSubrange(parameterNames, with: "()")
        }
        let fileName = NSString(string: filePath).lastPathComponent
        Swift.print("[\(fileName):\(line):\(functionSignature)] - ❌ \(message)")

        if visual {
            alert(title: "☠️", message: "🚫 \(message)")
        }
    }

    /// This function displays an OK alert if preferences.printEnabled and preferences.debugEnabled are true
    ///
    /// - parameters:
    ///     - message: The debug message.
    ///     - title: The alert's title.
    ///
    @objc open class func alert(title: String, message: String) {
        guard preferences.printEnabled && preferences.debugEnabled else { return }
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(OKAction)
            UIWindow.presentTopLevelAlert(alertController: alertController)
        }
    }
}
