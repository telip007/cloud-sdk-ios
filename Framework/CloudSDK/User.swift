//
//  User.swift
//  CloudSDK
//
//  Created by Victoria Teufel on 29.03.18.
//  Copyright © 2018 PACE. All rights reserved.
//

import UIKit

struct UserResponse: Codable {

    let user: User

}

/// Information about the logged in user
public struct User: Codable {

    /// Unique identifier
    public let uuid: String
    /// Email adress
    public let email: String
    /// User confirmed last version of terms of use
    public let confirmedLastTerms: Bool
    /// User confirmed last version of privacy terms
    public let confirmedLastPrivacy: Bool
    /// mobile phone number
    public let mobileNumber: String?
    /// first name
    public let firstName: String?
    /// last name
    public let lastName: String?
    /// gender, 'male' or 'female'
    public let gender: String?
    /// birthday, formatted as 'YYYY-MM-DD'
    public let birthday: String?
    /// URL to fetch user's avatar
    public let avatarURL: String?
    /// Unix timestamp of the date created
    public let createdAt: Int
    /// Onboarding fully completed
    public let onboardingCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case uuid
        case email
        case confirmedLastTerms = "confirmed_latest_terms"
        case confirmedLastPrivacy = "confirmed_latest_privacy"
        case mobileNumber = "mobile_number"
        case firstName = "first_name"
        case lastName = "last_name"
        case gender
        case birthday
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
        case onboardingCompleted = "onboarding_completed"
    }

}
