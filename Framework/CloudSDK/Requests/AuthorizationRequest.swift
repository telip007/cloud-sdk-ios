//
//  AuthorizationRequest.swift
//  CloudSDK
//
//  Created by Martin Dinh on 11.02.19.
//  Copyright © 2019 PACE. All rights reserved.
//

public class AuthorizationRequest: AuthorizationRequestProtocol, Decodable {
    public var clientId: String
    public var redirectUrl: String
    public var scope: String
    let deviceUUID: String
    let userAuthToken: String
    let responseType: String = "code"
    let codeChallengeMethod: String = "S256"
    var codeChallenge: String = ""
    var codeVerifier: String = ""
    var code: String = ""

    var authorizationParams: [String: String] {
        return [
            "client_id": clientId,
            "redirect_uri": redirectUrl,
            "response_type": responseType,
            "scope": scope,
            "code_verifier": codeVerifier,
            "code_challenge": codeChallenge,
            "code_challenge_method": codeChallengeMethod,
            "user_auth_token": userAuthToken,
            "device_uuid": deviceUUID
        ]
    }

    var accessTokenParams: [String: String] {
        return [
            "grant_type": "authorization_code",
            "client_id": clientId,
            "redirect_uri": redirectUrl,
            "code": code
        ]
    }

    public init(clientId: String, redirectUrl: String, scope: String, userAuthToken: String = "", deviceUUID: String = "") {
        self.clientId = clientId
        self.redirectUrl = redirectUrl
        self.scope = scope
        self.userAuthToken = userAuthToken
        self.deviceUUID = deviceUUID
    }
}
