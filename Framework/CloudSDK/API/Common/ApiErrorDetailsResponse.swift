//
//  APIErrorResponse.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 09.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

public struct ApiErrorDetailsResponse: Codable, CustomStringConvertible {
    public let errors: [ErrorObject]

    public var description: String {
        return "\(errors)"
    }
}

public struct ErrorObject: Codable, CustomStringConvertible {
    let id: String?
    let links: ErrorLink?
    let status: String?
    public let code: String?
    let title: String?
    let detail: String?
    let source: ErrorSource?
    let meta: ErrorMeta?

    public var description: String {
        var result: [String] = []

        let mirror = Mirror(reflecting: self)

        for (name, value) in mirror.children {
            guard let name = name else { continue }

            if let val = value as? String {
                result.append("\(name): \(val)")
                continue
            }

            result.append("\(name): \(value)")
        }

        return "[\(result.joined(separator: ", "))]"
    }
}

public struct ErrorLink: Codable, CustomStringConvertible {
    let about: String?

    public var description: String {
        guard let about = about else {
            return ""
        }

        return "ErrorLink: \(about)"
    }
}

public struct ErrorSource: Codable, CustomStringConvertible {
    let pointer: String?
    let parameter: String?

    public var description: String {
        var result = ""

        if let pointer = pointer {
            result += "pointer: \(pointer)"
        }

        if let parameter = parameter {
            result += ", parameter: \(parameter)"
        }

        return result
    }
}

public struct ErrorMeta: Codable {

}
