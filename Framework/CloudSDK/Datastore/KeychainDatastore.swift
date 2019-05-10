//
//  KeychainDatastore.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 09.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

class KeychainDataStore: Datastore {
    let keychain = KeychainSwift()

    func delete(_ key: String) {
        keychain.delete(key)
    }

    func getString(_ key: String) -> String? {
        return keychain.get(key)
    }

    func setString(_ value: String, forKey: String) {
        keychain.set(value, forKey: forKey)
    }

    func getData(_ key: String) -> Data? {
        return keychain.getData(key)
    }

    func setData(_ value: Data, forKey: String) {
        keychain.set(value, forKey: forKey)
    }
}
