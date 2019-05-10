//
//  URLExtensions.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 13.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

extension URL {
    var oAuthCode: String? {
        return URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .filter { $0.name == "code" }
            .first?
            .value
    }

    var state: String? {
        return URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .filter { $0.name == "state" }
            .first?
            .value
    }
}
