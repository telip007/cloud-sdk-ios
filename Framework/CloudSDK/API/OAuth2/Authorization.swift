//
//  Authorization.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 09.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

// swiftlint:disable nesting function_parameter_count
public extension ApiRequest {
    static var bypassAuthorizationKey: String { return "bypassAuthorizationKey" }

    var bypassAuthentication: Bool {
        return meta?[ApiRequest.bypassAuthorizationKey] as? Bool ?? false
    }
}

public extension ApiRequest {
    static func JsonApiRequest(id: UUID = UUID(),
                               method: HttpRequestMethod,
                               host: String,
                               path: String,
                               queryItems: [URLQueryItem]?,
                               body: Encodable?,
                               headers: [String: String]?,
                               meta: [String: Any]?) -> ApiRequest {
        return ApiRequest(
            method: method,
            host: host,
            path: path,
            queryItems: queryItems,
            body: body,
            headers: headers + [
                "Content-Type": "application/vnd.api+json",
                "Accept": "application/vnd.api+json"
            ],
            meta: meta
        )
    }

    static func JsonRequest(id: UUID = UUID(),
                            method: HttpRequestMethod,
                            host: String,
                            path: String,
                            queryItems: [URLQueryItem]?,
                            body: Encodable?,
                            headers: [String: String]?,
                            meta: [String: Any]?) -> ApiRequest {
        return ApiRequest(
            method: method,
            host: host,
            path: path,
            queryItems: queryItems,
            body: body,
            headers: headers + [
                "Content-Type": "application/json",
                "Accept": "application/json"
            ],
            meta: meta
        )
    }
}

public extension ApiRequest {
    enum ResponseType: String {
        case code
    }

    enum CodeChallengeMethod: String {
        case s256 = "S256"
    }

    static func authorize(host: String = Host.id.hostName,
                          clientId: String,
                          redirectUrl: String,
                          scope: String,
                          responseType: ResponseType = .code,
                          codeChallengeMethod: CodeChallengeMethod = .s256,
                          codeChallenge: String,
                          userAuthToken: String? = nil,
                          deviceUUID: String? = nil,
                          state: String = "",
                          code: String = "") -> ApiRequest {
        var pkceQueryItems: [URLQueryItem] = []

        if let userAuthToken = userAuthToken, let deviceUUID = deviceUUID {
            pkceQueryItems = [
                URLQueryItem(name: "user_auth_token", value: userAuthToken),
                URLQueryItem(name: "device_uuid", value: deviceUUID)
            ]
        }

        return JsonRequest(
            method: .get,
            host: host,
            path: "/oauth2/authorize",
            queryItems: [
                URLQueryItem(name: "state", value: state),
                URLQueryItem(name: "client_id", value: clientId),
                URLQueryItem(name: "redirect_uri", value: redirectUrl),
                URLQueryItem(name: "response_type", value: responseType.rawValue),
                URLQueryItem(name: "scope", value: scope),
                URLQueryItem(name: "code_challenge", value: codeChallenge),
                URLQueryItem(name: "code_challenge_method", value: codeChallengeMethod.rawValue)
            ] + pkceQueryItems,
            body: nil,
            headers: nil,
            meta: [bypassAuthorizationKey: true]
        )
    }

    struct AccessTokenData: Codable {
        let grantType = "authorization_code"
        let clientId: String
        let redirectUri: String
        let code: String
        let codeVerifier: String

        public init(clientId: String, redirectUri: String, code: String, codeVerifier: String) {
            self.clientId = clientId
            self.redirectUri = redirectUri
            self.code = code
            self.codeVerifier = codeVerifier
        }

        private enum CodingKeys: String, CodingKey {
            case grantType = "grant_type"
            case clientId = "client_id"
            case redirectUri = "redirect_uri"
            case code
            case codeVerifier = "code_verifier"
        }
    }

    static func token(host: String = Host.id.hostName,
                      accessTokenData: AccessTokenData) -> ApiRequest {
        return JsonRequest(
            method: .post,
            host: host,
            path: "/oauth2/token",
            queryItems: nil,
            body: accessTokenData,
            headers: nil,
            meta: [bypassAuthorizationKey: true]
        )
    }

    struct RefreshTokenData: Codable {
        let clientId: String
        let refreshToken: String
        let grantType: String = "refresh_token"

        public init(clientId: String, refreshToken: String) {
            self.clientId = clientId
            self.refreshToken = refreshToken
        }

        private enum CodingKeys: String, CodingKey {
            case clientId = "client_id"
            case refreshToken = "refresh_token"
            case grantType = "grant_type"
        }
    }

    static func token(host: String = Host.id.hostName,
                      refreshTokenData: RefreshTokenData) -> ApiRequest {
        return JsonRequest(
            method: .post,
            host: host,
            path: "/oauth2/token",
            queryItems: [],
            body: refreshTokenData,
            headers: nil,
            meta: [bypassAuthorizationKey: true]
        )
    }

    struct TokenResponseData: Codable {
        public let accessToken: String
        let tokenType: String
        let expiresIn: Int
        let refreshToken: String
        let createdAt: Int
        let scope: String

        var isValid: Bool {
            return Date(timeIntervalSince1970: TimeInterval(createdAt + expiresIn)) > Date()
        }

        private enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case tokenType = "token_type"
            case expiresIn = "expires_in"
            case refreshToken = "refresh_token"
            case createdAt = "created_at"
            case scope
        }
    }

    struct RevokeTokenData: Codable {
        let clientId: String
        let accessToken: String
    }

    static func revoke(host: String = Host.id.hostName, revokeTokenData: RevokeTokenData) -> ApiRequest {
        return JsonRequest(
            method: .post,
            host: host,
            path: "/oauth2/revoke",
            queryItems: [],
            body: revokeTokenData,
            headers: nil,
            meta: [bypassAuthorizationKey: true]
        )
    }
}
