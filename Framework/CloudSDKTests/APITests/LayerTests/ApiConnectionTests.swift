//
//  ApiConnectionTests.swift
//  CloudSDKTests
//
//  Created by Mike Kasperlik on 21.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import XCTest
@testable import CloudSDK

class ApiConnectionTests: XCTestCase {
    struct TestResponse: Decodable {
        let foo: String
        let bar: Int
    }

    func testSuccessfulJsonRequest() {
        let connection = ApiConnection(factory: MockFactory.shared)
        let request = ApiRequest(method: .get, host: "test.de", path: "/api/endpoint", queryItems: nil, body: nil, contentType: .json, headers: nil, meta: nil)
        let responseData = "{\"foo\":\"hello\", \"bar\":200}".data(using: .utf8)

        MockHttpConnection.shared.desiredResult = .success(NetworkResponse(data: responseData, statusCode: 200))
        connection.request(request, expect: TestResponse.self) { result in
            let response = try? result.get()
            XCTAssertEqual(response?.object?.foo, "hello")
            XCTAssertEqual(response?.object?.bar, 200)
        }
    }

    func testEmptyBodyIsNotParsed() {
        let connection = ApiConnection(factory: MockFactory.shared)
        let request = ApiRequest(method: .get, host: "test.de", path: "/api/endpoint", queryItems: nil, body: nil, contentType: .json, headers: nil, meta: nil)

        MockHttpConnection.shared.desiredResult = .success(NetworkResponse(data: nil, statusCode: 204))
        connection.request(request, expect: TestResponse.self) { result in
            do {
                XCTAssertNoThrow(try result.get())
                let response = try? result.get()
                XCTAssertEqual(response?.code, HttpStatusCode.okNoContent)
            } catch {}
        }
    }

    func testZeroByteBodyIsNotParsed() {
        let connection = ApiConnection(factory: MockFactory.shared)
        let request = ApiRequest(method: .get, host: "test.de", path: "/api/endpoint", queryItems: nil, body: nil, contentType: .json, headers: nil, meta: nil)

        MockHttpConnection.shared.desiredResult = .success(NetworkResponse(data: Data(), statusCode: 204))
        connection.request(request, expect: TestResponse.self) { result in
            do {
                XCTAssertNoThrow(try result.get())
                let response = try? result.get()
                XCTAssertEqual(response?.code, HttpStatusCode.okNoContent)
            } catch {}
        }
    }

    func testBehaviorsInvoked() {

    }
}
