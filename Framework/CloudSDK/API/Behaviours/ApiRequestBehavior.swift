//
//  APIRequestBehavior.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 09.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

public protocol ApiRequestBehavior {
    var headers: [String: String] { get }

    func beforeSend(request: ApiRequest)
    func onSuccess(_ responseCode: HttpStatusCode, for request: ApiRequest)
    func onFailure(_ error: Error, for request: ApiRequest)
}

extension ApiRequestBehavior {
    var headers: [String: String] { return [:] }

    func beforeSend(request: ApiRequest) {}
    func onSuccess(_ responseCode: HttpStatusCode, for request: ApiRequest) {}
    func onFailure(_ error: Error, for request: ApiRequest) {}
}
