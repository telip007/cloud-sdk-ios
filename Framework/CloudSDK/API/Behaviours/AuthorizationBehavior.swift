//
//  AuthorizationBehavior.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 09.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

class AuthorizationBehavior: ApiRequestBehavior {
    var tokenData: ApiRequest.TokenResponseData?

    var headers: [String: String] {
        if let accessToken = tokenData?.accessToken {
            return ["Authorization": "Bearer \(accessToken)"]
        }

        return [:]
    }

    func set(tokenData: ApiRequest.TokenResponseData?) {
        self.tokenData = tokenData
    }
}
