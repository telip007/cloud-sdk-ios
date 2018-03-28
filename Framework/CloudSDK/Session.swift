//
//  Session.swift
//  CloudSDK
//
//  Created by Victoria Teufel on 29.03.18.
//  Copyright © 2018 PACE. All rights reserved.
//

import Foundation

class Session: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    let scope: String
    let createdAt: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType =  "token_type"
        case expiresIn = "expires_in"
        case scope
        case createdAt = "created_at"
    }

    let httpRequest = HTTPRequest()

    init(accessToken: String, refreshToken: String, tokenType: String, expiresIn: Int, scope: String, createdAt: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.scope = scope
        self.createdAt = createdAt
    }

    func refresh(_ completion: @escaping (Session?) -> Void) {
        guard let authRequest = Keychain.oAuthApplication else {
            completion(nil)
            return
        }

        var body = authRequest.accessTokenParams
        body["refresh_token"] = refreshToken
        body["grant_type"] = "refresh_token"
        let data = try? JSONEncoder().encode(body)

        httpRequest.perform(path: "oauth2/token", method: .post(data)) { (data, response, _) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let data = data,
                let session = try? JSONDecoder().decode(Session.self, from: data) else {
                    completion(nil)
                    return
            }

            completion(session)
        }
    }

    func invalidate() {
        guard let authRequest = Keychain.oAuthApplication else {
            return
        }

        var body = [String: String]()
        body["token"] = refreshToken
        body["client_id"] = authRequest.clientId
        body["client_secret"] = authRequest.clientSecret
        let data = try? JSONEncoder().encode(body)

        httpRequest.perform(path: "oauth2/revoke", method: .post(data)) { (_, _, _) in }
    }
}
