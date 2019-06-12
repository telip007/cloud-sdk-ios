//
//  Datastore.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 09.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

protocol Datastore {
    func delete(_ key: String)

    func setString(_ value: String, forKey: String)
    func getString(_ key: String) -> String?

    func setData(_ value: Data, forKey: String)
    func getData(_ key: String) -> Data?
}
