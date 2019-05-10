//
//  DefaultFactory.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 16.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

protocol Factory {
    static var shared: Factory { get }

    var authConnection: AuthorizationConnection { get }
    var apiConnection: APIConnection { get }
    var httpConnection: HttpConnection { get }
    var datastore: Datastore { get }
    var logger: Logger { get }
}

final class DefaultFactory: Factory {
    static var shared: Factory = DefaultFactory()

    private init() {}

    var authConnection: AuthorizationConnection { return OAuthConnection.shared }
    var apiConnection: APIConnection { return ApiConnection(factory: self) }
    var httpConnection: HttpConnection { return URLHttpConnection() }
    var datastore: Datastore { return KeychainDataStore() }
    var logger: Logger { return SystemLogger() }
}
