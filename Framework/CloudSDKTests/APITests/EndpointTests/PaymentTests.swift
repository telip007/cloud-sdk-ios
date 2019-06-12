//
//  PaymentTests.swift
//  CloudSDKTests
//
//  Created by Martin Dinh on 22.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import XCTest
@testable import CloudSDK

class PaymentTests: XCTestCase {
    let host: String = "pace.test"
    var connection: ApiConnection!

    override func setUp() {
        connection = ApiConnection(factory: MockFactory.shared)
    }

    func testRegisterSepaDirectMethodData() {
        let address = ApiRequest.AddressAttributes(street: "Haid-und-Neu-Str.", houseNo: "18", postalCode: "76131", city: "Karlsruhe", countryCode: "DE")
        let sepaAttributes = ApiRequest.SepaAttributes(iban: "DE89 3704 0044 0532 0130 00",
                                                       title: "Prof. Dr.", firstName: "Jon", lastName: "Smith",
                                                       company: "Clean House GmbH", address: address)
        let registerData = ApiRequest.RegisterSepaDirectMethodRequest(id: "2a1319c3-c136-495d-b59a-47b3246d08af", attributes: sepaAttributes)
        let responseData =
            """
            {
              "data": {
                "type": "paymentMethod",
                "id": "d7101f72-a672-453c-9d36-d5809ef0ded6",
                "attributes": {
                  "kind": "sepa",
                  "identificationString": "DEUTSCHEBANK XX 3000"
                }
              }
            }
            """.data(using: .utf8)!

        MockHttpConnection.shared.desiredResult = .success(NetworkResponse(data: responseData, statusCode: HttpStatusCode.created.rawValue))
        connection.request(.registerSepaDirectMethod(host: host, body: registerData), expect: ApiRequest.RegisterSepaDirectMethodResponse.self) { result in
            let response = try? result.get()
            XCTAssertEqual(response?.object?.data.id, "d7101f72-a672-453c-9d36-d5809ef0ded6")
            XCTAssertEqual(response?.object?.data.type, "paymentMethod")
            XCTAssertEqual(response?.object?.data.attributes?.kind, "sepa")
            XCTAssertEqual(response?.object?.data.attributes?.identificationString, "DEUTSCHEBANK XX 3000")
        }
    }

    func testRetrievingAllPayments() {
        let responseData =
            """
            {
              "data": [
                {
                  "type": "paymentMethod",
                  "id": "d7101f72-a672-453c-9d36-d5809ef0ded6",
                  "attributes": {
                    "kind": "sepa",
                    "identificationString": "DEUTSCHEBANK XX 3000"
                  },
                  "relationships": {
                    "paymentTokens": {
                      "data": [
                        {
                          "type": "paymentToken",
                          "id": "33331f72-a672-453c-9d36-d5809ef0ded6"
                        }
                      ]
                    }
                  }
                }
              ]
            }
            """.data(using: .utf8)!
        MockHttpConnection.shared.desiredResult = .success(NetworkResponse(data: responseData, statusCode: HttpStatusCode.created.rawValue))
        connection.request(.getAllPaymentMethods(host: host), expect: ApiRequest.GetAllPaymentMethodsResponse.self) { result in
            let response = try? result.get()
            let responseData = response?.object?.data ?? []

            XCTAssertEqual(response?.object?.data.first?.relationships?.paymentTokens?.data.first?.id, "33331f72-a672-453c-9d36-d5809ef0ded6")
            XCTAssertEqual(responseData.count, 1)
            XCTAssertEqual(responseData.first?.attributes?.identificationString, "DEUTSCHEBANK XX 3000")
        }
    }

    func testGetPreAuthorizedPaymentMethods() {
        let responseData =
            """
            {
              "data": [
                {
                  "type": "paymentMethod",
                  "id": "d7101f72-a672-453c-9d36-d5809ef0ded6",
                  "attributes": {
                    "kind": "sepa",
                    "identificationString": "DEUTSCHEBANK XX 3000"
                  },
                  "relationships": {
                    "paymentTokens": {
                      "data": [
                        {
                          "type": "paymentToken",
                          "id": "33331f72-a672-453c-9d36-d5809ef0ded6"
                        }
                      ]
                    }
                  }
                }
              ],
              "included": [
                {
                  "type": "paymentToken",
                  "id": "33331f72-a672-453c-9d36-d5809ef0ded6",
                  "attributes": {
                    "amount": 23,
                    "currency": "EUR",
                    "value": "12c52345c1x34",
                    "validUntil": "2019-06-07T11:20:32Z",
                    "purposePRNs": [
                      "prn:poi:gas-stations:124e522d-65ef-4386-b7e0-00d2eceeadc6"
                    ]
                  }
                }
              ]
            }
            """.data(using: .utf8)!

        MockHttpConnection.shared.desiredResult = .success(NetworkResponse(data: responseData, statusCode: HttpStatusCode.created.rawValue))
        connection.request(.getPreAuthorizedPaymentMethods(host: host), expect: ApiRequest.GetAllPaymentMethodsWithPreAuthorizedResponse.self) { result in
            let response = try? result.get()
            let responseData = response?.object

            XCTAssertEqual(1, responseData?.paymentTokensMethodMapping.count)
            XCTAssertEqual("d7101f72-a672-453c-9d36-d5809ef0ded6", responseData?.paymentTokensMethodMapping.first?.key)
            XCTAssertEqual("12c52345c1x34", responseData?.paymentTokensMethodMapping["d7101f72-a672-453c-9d36-d5809ef0ded6"]?.value)
        }
    }
}
