//
//  SystemLogger.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 09.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation
import os.log

class SystemLogger: Logger {
    func log(_ tag: String, _ message: String) {
        if #available(iOS 10.0, *) {
            let logCategory = OSLog(subsystem: "CloudSDK", category: tag)
            os_log("%{public}@", log: logCategory, type: .info, message)
        } else {
            NSLog("[\(tag)] \(message)")
        }
        // print("Test commit")
    }
}
