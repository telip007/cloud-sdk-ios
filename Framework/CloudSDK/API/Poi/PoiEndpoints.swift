//
//  PoiEndpoints.swift
//  CloudSDK
//
//  Created by Martin Dinh on 27.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

public extension ApiRequest {
    private static let poiServiceVersion = "beta"

    static let locationBasedAppType: String = "locationBasedApp"

    class QueryLocationBasedAppsResponse: DataArrayContainer<FuelingAttributes, Void, Void, FuelingMeta> {}

    struct FuelingAttributes: Codable {
        let appType: AppType?
        let title: String?
        let subtitle: String?
        let logoUrl: String?
        let pwaUrl: String?
        let androidInstantAppUrl: String?
        let cache: String?
        let createdAt: String?
        let updatedAt: String?
        let deletedAt: String?
        let references: [String]?
    }

    struct FuelingMeta: Codable {
        let insideAppArea: Bool
        let appArea: AppAreaType
    }

    struct AppAreaType: Codable {
        let type: String
        let coordinates: [[Float]]
    }

    static func queryLocationBasedApps(host: String = Host.api.hostName,
                                       latitude: Float,
                                       longitude: Float,
                                       appType: AppType = AppType.fueling) -> ApiRequest {
        return JsonApiRequest(
            method: .get, host: host, path: "/poi/\(poiServiceVersion)/apps/query",
            queryItems: [
                URLQueryItem(name: "filter[latitude]", value: "\(latitude)"),
                URLQueryItem(name: "filter[longitude]", value: "\(longitude)"),
                URLQueryItem(name: "filter[appType]", value: appType.rawValue)
            ],
            body: nil, headers: nil, meta: nil
        )
    }

    enum AppType: String, Codable {
        case fueling
    }

    enum CachePolicy: String {
        case preload, approaching
    }
}
