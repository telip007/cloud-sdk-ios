//
//  PoiTests.swift
//  CloudSDKTests
//
//  Created by Mike Kasperlik on 11.06.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import XCTest
@testable import CloudSDK

class PoiTests: XCTestCase {
    let host: String = "pace.test"
    var connection: ApiConnection!

    override func setUp() {
        connection = ApiConnection(factory: MockFactory.shared)
    }

    let queryPoi200responseWithApps: String = """
    {
        "data": [
            {
                "type": "locationBasedAppWithRefs",
                "id": "f106ac99-213c-4cf7-8c1b-1e841516026b",
                "attributes": {
                "appType": "fueling",
                "title": "PACE Fueling App",
                "subtitle": "Zahle bargeldlos mit der PACE Fueling App",
                "logoUrl": "http://via.placeholder.com/200x200",
                "pwaUrl": "https://cdn.example.org/pwa/fueling.html",
                "androidInstantAppUrl": "https://cdn.example.org/pwa/fueling.apk",
                "cache": "approaching",
                "references": [
                    "prn:poi:gas-stations:24841a1c-39bd-422d-9164-d420e000243b"
                ],
                "createdAt": "2018-01-01T00:00:00",
                "updatedAt": "2018-06-01T00:00:00",
                "deletedAt": "2018-12-01T00:00:00"
                }
            }
        ]
    }
    """

    let queryPoi200responseWithoutApps: String = """
    {
        "data": [
        ]
    }
    """
    
    let getAppsById200response: String = """
    {
      "data": {
        "type": "locationBasedApp",
        "id": "f106ac99-213c-4cf7-8c1b-1e841516026b",
        "attributes": {
          "appType": "fueling",
          "title": "PACE Fueling App",
          "subtitle": "Zahle bargeldlos mit der PACE Fueling App",
          "logoUrl": "http://via.placeholder.com/200x200",
          "pwaUrl": "https://cdn.example.org/pwa/fueling.html",
          "androidInstantAppUrl": "https://cdn.example.org/pwa/fueling.apk",
          "cache": "approaching",
          "createdAt": "2018-01-01T00:00:00",
          "updatedAt": "2018-06-01T00:00:00",
          "deletedAt": "2018-12-01T00:00:00"
        }
      }
    }
    """

    func testValidResponseWithApps() {
        let responseData = queryPoi200responseWithApps.data(using: .utf8)!
        MockHttpConnection.shared.desiredResult = .success(NetworkResponse(data: responseData, statusCode: HttpStatusCode.ok.rawValue))

        connection.request(.queryLocationBasedApps(host: host, latitude: 0.0, longitude: 0.0, appType: .fueling), expect: ApiRequest.QueryLocationBasedAppsResponse.self) { result in
            let response = try? result.get()
            XCTAssertEqual(response?.code, HttpStatusCode.ok)
            XCTAssertEqual(response?.object?.data.count, 1)

            let app = response!.object!.data.first!

            XCTAssertEqual(app.id, "f106ac99-213c-4cf7-8c1b-1e841516026b")
            XCTAssertEqual(app.type, "locationBasedAppWithRefs")
            XCTAssertEqual(app.attributes?.appType, ApiRequest.AppType.fueling)
            XCTAssertEqual(app.attributes?.references?.first, "prn:poi:gas-stations:24841a1c-39bd-422d-9164-d420e000243b")
        }
    }

    func testValidResponseWithoutApps() {
        let responseData = queryPoi200responseWithoutApps.data(using: .utf8)!
        MockHttpConnection.shared.desiredResult = .success(NetworkResponse(data: responseData, statusCode: HttpStatusCode.ok.rawValue))

        connection.request(.queryLocationBasedApps(host: host, latitude: 0.0, longitude: 0.0, appType: .fueling), expect: ApiRequest.QueryLocationBasedAppsResponse.self) { result in
            let response = try? result.get()
            XCTAssertEqual(response?.code, HttpStatusCode.ok)
            XCTAssertEqual(response?.object?.data.count, 0)
        }
    }
    
    func testGetAppById() {
        let responseData = getAppsById200response.data(using: .utf8)!
        MockHttpConnection.shared.desiredResult = .success(NetworkResponse(data: responseData, statusCode: HttpStatusCode.ok.rawValue))
        
        connection.request(.getLocationBasedApp(host: host, byId: "f106ac99-213c-4cf7-8c1b-1e841516026b"), expect: ApiRequest.GetLocationBasedAppResponse.self) { result in
            let response = try? result.get()
            XCTAssertEqual(response?.code, HttpStatusCode.ok)
            
            let app = response!.object!.data
            
            XCTAssertEqual(app.id, "f106ac99-213c-4cf7-8c1b-1e841516026b")
            XCTAssertEqual(app.type, "locationBasedApp")
            XCTAssertEqual(app.attributes?.appType, ApiRequest.AppType.fueling)
        }
    }
}
