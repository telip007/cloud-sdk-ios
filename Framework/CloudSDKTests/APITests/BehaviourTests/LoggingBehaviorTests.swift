//
//  LoggingBehaviorTests.swift
//  CloudSDKTests
//
//  Created by Mike Kasperlik on 10.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation
import XCTest
@testable import CloudSDK

class LoggingBehaviorTests: XCTestCase {
    let request = ApiRequest(
        method: .post,
        host: "www.test.xyz",
        path: "/foo/bar",
        queryItems: [URLQueryItem(name: "parameter", value: "value")],
        body: nil,
        contentType: .json,
        headers: nil,
        meta: nil
    )

    var loggingBehavior: LoggingBehavior!

    override func setUp() {
        loggingBehavior = LoggingBehavior(factory: MockFactory.shared)
        MockLogger.shared.logs.removeAll()
    }

    func testLogsRequest() {
        loggingBehavior.beforeSend(request: request)

        XCTAssertEqual(MockLogger.shared.logs[0], "[API] [\(request.id)] POST https://www.test.xyz/foo/bar?parameter=value [-] [-]")
    }

    func testLogsSuccess() {
        loggingBehavior.onSuccess(.ok, for: request)

        XCTAssertEqual(MockLogger.shared.logs[0], "[API] [\(request.id)] ok")
    }

    func testLogsFailure() {
        loggingBehavior.onFailure(ApiError.httpError(code: 400, error: ApiErrorDetailsResponse(errors: [])), for: request)

        XCTAssertEqual(MockLogger.shared.logs[0], "[API] [\(request.id)] Failed with error: Http error (code: 400, details: [].")
    }
}
