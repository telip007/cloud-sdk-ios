//
//  HttpStatusCode.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 21.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

public enum HttpStatusCode: Int {
    case ok = 200
    case created = 201
    case okNoContent = 204

    case redirect = 302

    case badRequest = 400
    case unauthorized = 401
    case notFound = 404

    init?(from code: Int?) {
        if let code = code, let httpResponseCode = HttpStatusCode(rawValue: code) {
            self = httpResponseCode
        } else {
            return nil
        }
    }

    var successRange: Range<Int> {
        return 200 ..< 299
    }

    var redirectRange: Range<Int> {
        return 300 ..< 399
    }
    var errorRange: Range<Int> {
        return 400 ..< 999
    }

    var success: Bool {
        return successRange.contains(self.rawValue)
    }

    var redirect: Bool {
        return redirectRange.contains(self.rawValue)
    }

    var error: Bool {
        return errorRange.contains(self.rawValue)
    }
}
