//
//  Helper.swift
//
//  Created by Akash Desai on 8/7/18.
//  Copyright © 2018 Boundless Mind. All rights reserved.
//

import Foundation

class Helper: NSObject {
    static var shared = Helper()

    var logObject = "Welcome!"

    func appendLog(_ str: String) {
        logObject += "\n" + str
        print(str)
    }
}
