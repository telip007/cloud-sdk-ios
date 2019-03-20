//
//  AuthorizationRequestProtocol.swift
//  CloudSDK
//
//  Created by Martin Dinh on 11.02.19.
//  Copyright © 2019 PACE. All rights reserved.
//

public protocol AuthorizationRequestProtocol: Codable {
    /// client id
    var clientId: String { get }
    /// client secret
    var clientSecret: String { get }
    /// redirect url
    var redirectUrl: String { get }
    /// scopes
    var scope: String { get }
}
