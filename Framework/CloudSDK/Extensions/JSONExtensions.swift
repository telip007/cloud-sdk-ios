//
//  JSONExtensions.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 17.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

extension JSONDecoder {
    static var shared: JSONDecoder {
        let decoder = JSONDecoder()
        return decoder
    }
}

extension JSONEncoder {
    static var shared: JSONEncoder {
        let decoder = JSONEncoder()
        return decoder
    }
}
