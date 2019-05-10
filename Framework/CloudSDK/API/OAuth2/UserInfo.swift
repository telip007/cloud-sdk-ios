//
//  Me.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 20.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

public extension ApiRequest {
    static func userInfo(host: String) -> ApiRequest {
        return ApiRequest(method: .get, host: host, path: "/oauth2/me", queryItems: nil, body: nil, contentType: .json, headers: nil, meta: nil)
    }

    struct UserResponseData: Decodable {
        public let user: UserInfoResponseData
    }

    struct UserInfoResponseData: Decodable {
        public let uuid: String?
        public let email: String?
        public let confirmedLatestTerms: Bool?
        public let confirmedLatestPrivacy: Bool?
        public let mobileNumber: String?
        public let firstName: String?
        public let lastName: String?
        public let gender: String?
        public let birthday: String?
        public let avatarUrl: String?
        public let createdAt: Int?
        public let onboardingCompleted: Bool?

        private enum CodingKeys: String, CodingKey {
            case uuid
            case email
            case confirmedLatestTerms = "confirmed_latest_terms"
            case confirmedLatestPrivacy = "confirmed_latest_privacy"
            case mobileNumber = "mobile_number"
            case firstName = "first_name"
            case lastName = "last_name"
            case gender
            case birthday
            case avatarUrl = "avatar_url"
            case createdAt = "created_at"
            case onboardingCompleted = "onboarding_completed"
        }
    }
}
