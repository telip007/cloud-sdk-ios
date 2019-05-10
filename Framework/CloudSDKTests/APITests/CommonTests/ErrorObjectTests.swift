//
//  ErrorObjectTests.swift
//  CloudSDKTests
//
//  Created by Martin Dinh on 27.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import XCTest
@testable import CloudSDK

class ErrorObjectTests: XCTestCase {
    func testEmptyObject() {
        let json = #"{ "errors": [] }"#.data(using: .utf8)!

        let errors = try! JSONDecoder().decode(ApiErrorDetailsResponse.self, from: json)
        XCTAssertEqual(errors.errors.count, 0)
    }

    func testMultipleObjects() {
        let json =
        """
        {
            "errors": [
                {
                    "id": "string",
                    "links": {
                        "about": "string"
                    },
                    "status": "string",
                    "code": "string",
                    "title": "string",
                    "detail": "string",
                    "source": {
                        "pointer": "string",
                        "parameter": "string"
                    },
                    "meta": {}
                }
            ]
        }
        """.data(using: .utf8)!

        let errors = try! JSONDecoder().decode(ApiErrorDetailsResponse.self, from: json)
        XCTAssertEqual(errors.errors.count, 1)
        XCTAssertEqual(errors.errors.first?.links?.about, "string")
        XCTAssertEqual(errors.errors.first?.source?.pointer, "string")
        XCTAssertNotNil(errors.errors.first?.meta)
    }

    func testMultipleObjectsWithMissingFields() {
        let json =
        """
        {
          "errors": [
            {
              "id": "bjlv8efisj4duplk7n5g",
              "title": "countryCode is invalid",
              "detail": "non zero value required",
              "status": "422",
              "source": {
                "pointer": "/address/countrycode"
              }
            },
            {
              "id": "bjlv8efisj4duplk7n5g",
              "title": "houseNo is invalid",
              "detail": "non zero value required",
              "status": "422",
              "source": {
                "pointer": "/address/houseno"
              }
            },
            {
              "id": "bjlv8efisj4duplk7n5g",
              "title": "address is invalid",
              "detail": "non zero value required",
              "status": "422",
              "source": {
                "pointer": "/address"
              }
            },
            {
              "id": "bjlv8efisj4duplk7n5g",
              "title": "address is invalid",
              "detail": "non zero value required",
              "status": "422",
              "source": {
                "pointer": "/address"
              }
            }
          ]
        }
        """.data(using: .utf8)!

        let errors = try! JSONDecoder().decode(ApiErrorDetailsResponse.self, from: json)
        XCTAssertEqual(errors.errors.count, 4)
        XCTAssertEqual(errors.errors[0].status, "422")
        XCTAssertEqual(errors.errors[0].source?.pointer, "/address/countrycode")
        XCTAssertEqual(errors.errors[3].id, "bjlv8efisj4duplk7n5g")
    }
}
