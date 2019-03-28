//
//  Keychain.swift
//  CloudSDK
//
//  Created by Victoria Teufel on 28.03.18.
//  Copyright © 2018 PACE. All rights reserved.
//

import Foundation

class Keychain {
    static let sessionKey = "pace.car.cloudmobilesdk.oAuthSession"
    static var session: Session? {
        get {
            guard let data = KeychainSwift().getData(sessionKey) else {
                return nil
            }

            return try? JSONDecoder().decode(Session.self, from: data)
        }
        set {
            if let newValue = newValue {
                if let data = try? JSONEncoder().encode(newValue) {
                    KeychainSwift().set(data, forKey: sessionKey, withAccess: .accessibleAlways)
                }
            } else {
                KeychainSwift().delete(sessionKey)
            }
        }
    }

    static let applicationKey = "pace.car.cloudmobilesdk.oAuthApplication"
    static var oAuthApplication: AuthorizationRequest? {
        get {
            guard let data = KeychainSwift().getData(applicationKey) else {
                return nil
            }

            return try? JSONDecoder().decode(AuthorizationRequest.self, from: data)
        }
        set {
            if let newValue = newValue {
                if let data = try? JSONEncoder().encode(newValue) {
                    KeychainSwift().set(data, forKey: applicationKey, withAccess: .accessibleAlways)
                }
            } else {
                KeychainSwift().delete(applicationKey)
            }
        }
    }
}
