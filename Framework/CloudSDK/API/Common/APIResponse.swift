//
//  APIResponse.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 09.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

public struct EmptyResponse: Codable {}

public struct ApiResponse<T> where T: Decodable {
    public let code: HttpStatusCode
    public var object: T?
}
