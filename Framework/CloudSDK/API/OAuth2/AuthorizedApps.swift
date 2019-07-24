//
//  AuthorizedApps.swift
//  CloudSDK
//
//  Created by Martin Dinh on 19.07.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

public extension ApiRequest {
    static func getAuthorizedApps(host: String) -> ApiRequest {
        return JsonRequest(method: .get, host: host, path: "/oauth2/authorized_applications", queryItems: nil, body: nil, headers: nil, meta: nil)
    }

    static func revokeAccess(host: String, appUUID: String) -> ApiRequest {
        return JsonRequest(method: .delete, host: host, path: "/oauth2/authorized_applications/\(appUUID)", queryItems: nil, body: nil, headers: nil, meta: nil)
    }

    struct AuthorizedApps: Decodable {
        public let apps: [AuthorizedApp]

        private enum CodingKeys: String, CodingKey {
            case apps = "authorized_applications"
        }
    }

    struct AuthorizedApp: Decodable {
        public var uuid, name, scopes, partnerURL, authorizedSince: String?

        private enum CodingKeys: String, CodingKey {
            case uuid, name, scopes
            case partnerURL = "partner_url"
            case authorizedSince = "authorized_since"
        }
    }
}
