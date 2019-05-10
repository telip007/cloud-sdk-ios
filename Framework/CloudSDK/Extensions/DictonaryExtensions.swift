//
//  DictonaryExtensions.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 16.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

extension Dictionary {
    static func + (lhs: [Key: Value]?, rhs: [Key: Value]) -> [Key: Value] {
        var result = [Key: Value]()
        lhs?.forEach { result.updateValue($0.value, forKey: $0.key) }
        rhs.forEach { result.updateValue($0.value, forKey: $0.key) }

        return result
    }

    static func + (lhs: [Key: Value], rhs: [Key: Value]?) -> [Key: Value] {
        var result = [Key: Value]()
        lhs.forEach { result.updateValue($0.value, forKey: $0.key) }
        rhs?.forEach { result.updateValue($0.value, forKey: $0.key) }

        return result
    }
}
