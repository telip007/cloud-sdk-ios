//
//  CloudSDKTests.swift
//  CloudSDKTests
//
//  Created by Mike Kasperlik on 09.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import XCTest
@testable import CloudSDK

class MockHttpConnection: HttpConnection {
    static let shared = MockHttpConnection()

    private init() {}

    var desiredResult: Result<NetworkResponse, Error> = .failure(ApiError.unknownServerError)
    var delegate: HttpConnectionDelegate?

    func execute(request: HttpRequest, completionHandler: @escaping (Result<NetworkResponse, Error>) -> Void) -> Int {
        completionHandler(desiredResult)
        return 1337
    }
}

class MockFactory: Factory {
    static var shared: Factory = MockFactory()

    private init() {}

    var authConnection: AuthorizationConnection { fatalError() }
    var apiConnection: APIConnection { fatalError() }
    var httpConnection: HttpConnection { return MockHttpConnection.shared }
    var datastore: Datastore { return KeychainDataStore() }
    var logger: Logger { return MockLogger.shared }
}

class MockLogger: Logger {
    static let shared: MockLogger = MockLogger()
    var logs: [String] = []

    private init() {}

    func log(_ tag: String, _ message: String) {
        logs.append("[\(tag)] \(message)")
    }
}
