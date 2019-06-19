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
    class GetLocationBasedAppResponse: DataContainer<FuelingAttributes, Void, Void, Void> {}

    struct FuelingAttributes: Codable {
        public let appType: AppType?
        public let title: String?
        public let subtitle: String?
        public let logoUrl: String?
        public let pwaUrl: String?
        public let androidInstantAppUrl: String?
        public let cache: String?
        public let createdAt: String?
        public let updatedAt: String?
        public let deletedAt: String?
        public let references: [String]?
    }

    struct FuelingMeta: Codable {
        public let insideAppArea: Bool
        public let appArea: AppAreaType
    }

    struct AppAreaType: Codable {
        public let type: String
        public let coordinates: [[Float]]
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
    
    static func getLocationBasedApp(host: String = Host.api.hostName,
                                    byId id: String) -> ApiRequest {
        return JsonApiRequest(
            method: .get,
            host: host,
            path: "/poi/\(poiServiceVersion)/apps/\(id)",
            queryItems: nil,
            body: nil,
            headers: nil,
            meta: nil
        )
    }

    enum AppType: String, Codable {
        case fueling
    }

    enum CachePolicy: String {
        case preload, approaching
    }
}
