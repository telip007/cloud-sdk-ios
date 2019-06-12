//
//  APIRequest.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 09.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

public enum ContentType {
    case json
    case protocolBuffer
}

public enum Host: String {
    case id = "id.pace.cloud"
    case api = "api.pace.cloud"

    public var hostName: String {
        return rawValue
    }
}

public class ApiRequest: Equatable {
    public typealias Void = EmptyResponse

    let id: UUID
    let method: HttpRequestMethod
    public var host: String
    let path: String
    let queryItems: [URLQueryItem]?
    let body: Encodable?
    let contentType: ContentType
    var headers: [String: String]?
    let meta: [String: Any]?

    init(id: UUID = UUID(),
         method: HttpRequestMethod,
         host: String,
         path: String,
         queryItems: [URLQueryItem]? = nil,
         body: Encodable? = nil,
         contentType: ContentType = .json,
         headers: [String: String]? = nil,
         meta: [String: Any]? = nil) {
        self.id = id
        self.method = method
        self.host = host
        self.path = path
        self.queryItems = queryItems
        self.body = body
        self.contentType = contentType
        self.headers = headers
        self.meta = meta
    }

    public static func == (lhs: ApiRequest, rhs: ApiRequest) -> Bool {
        return lhs.id == rhs.id
    }
}

extension ApiRequest {
    var url: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        components.queryItems = queryItems

        guard let url = components.url else {
            fatalError("Invalid url: \(components)")
        }

        return url
    }

    public func encode() -> Data? {
        guard let body = body else { return nil }

        switch contentType {
        case .json:
            return body.encode(with: JSONEncoder.shared)

        default:
            fatalError("Not implemented")
        }
    }
}

extension Encodable {
    func encode(with jsonEncoder: JSONEncoder) -> Data? {
        return try? jsonEncoder.encode(self)
    }
}

extension ApiRequest {
    var networkRequest: HttpRequest {
        return HttpRequest(url: url,
                           body: encode(),
                           method: method,
                           headers: headers)
    }
}

extension Data {
    public func decode<T>(contentType: ContentType) throws -> T? where T: Decodable {
        switch contentType {
        case .json:
            return try JSONDecoder.shared.decode(T.self, from: self)

        default:
            fatalError("Not implemented")
        }
    }
}
