//
//  Keychain.swift
//  CloudSDK
//
//  Created by Victoria Teufel on 28.03.18.
//  Copyright © 2018 PACE. All rights reserved.
//

import Foundation

class Keychain {
    static let KEYCHAIN_USER_KEY = "cockpitAccount"
    static var userAuthToken: Session? {
        get {
            guard let data = KeychainSwift().getData(KEYCHAIN_USER_KEY) else {
                return nil
            }

            return try? JSONDecoder().decode(Session.self, from: data)
        }
        set {
            if let newValue = newValue {
                if let data = try? JSONEncoder().encode(newValue) {
                    KeychainSwift().set(data, forKey: KEYCHAIN_USER_KEY, withAccess: .accessibleAlways)
                }
            } else {
                KeychainSwift().delete(KEYCHAIN_USER_KEY)
            }
        }
    }

    static let KEYCHAIN_APPLICATION_KEY = "oAuthApplication"
    static var oAuthApplication: AuthorizationRequest? {
        get {
            guard let data = KeychainSwift().getData(KEYCHAIN_APPLICATION_KEY) else {
                return nil
            }

            return try? JSONDecoder().decode(AuthorizationRequest.self, from: data)
        }
        set {
            if let newValue = newValue {
                if let data = try? JSONEncoder().encode(newValue) {
                    KeychainSwift().set(data, forKey: KEYCHAIN_APPLICATION_KEY, withAccess: .accessibleAlways)
                }
            } else {
                KeychainSwift().delete(KEYCHAIN_APPLICATION_KEY)
            }
        }
    }
}
