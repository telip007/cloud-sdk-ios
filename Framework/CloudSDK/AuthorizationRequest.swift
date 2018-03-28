//
//  AuthorizationRequest.swift
//  CloudSDK
//
//  Created by Victoria Teufel on 28.03.18.
//  Copyright © 2018 PACE. All rights reserved.
//

import Foundation

/// Request for OAuth authorization
public struct AuthorizationRequest: Codable {

    /// client id
    public let clientId: String
    /// client secret
    public let clientSecret: String
    /// redirect url
    public let redirectUrl: String
    /// scopes
    public let scope: String
    let responseType: String = "code"

    /// Creates a new AuthorizationRequest
    public init(clientId: String, clientSecret: String, redirectUrl: String, scope: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectUrl = redirectUrl
        self.scope = scope
    }

    var authorizationParams: [String: String] {
        return [
            "client_id": clientId,
            "redirect_uri": redirectUrl.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "",
            "response_type": responseType,
            "scope": scope
        ]
    }

    var accessTokenParams: [String: String] {
        return [
            "grant_type": "authorization_code",
            "client_id": clientId,
            "redirect_uri": redirectUrl,
            "client_secret": clientSecret
        ]
    }

}
