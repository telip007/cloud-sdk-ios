//
//  LoggingBehavior.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 09.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

class LoggingBehavior: ApiRequestBehavior {
    enum Level {
        case basic
        case withHeaders
        case withBody
    }

    let tag = "API"
    var level: Level = .basic
    var logger: Logger

    init(factory: Factory) {
        self.logger = factory.logger
    }

    func beforeSend(request: ApiRequest) {
        var body = "-"

        if let data = request.encode() {
            body = String(data: data, encoding: .utf8) ?? "-"
        }

        let headers = request
            .headers?
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")
            ?? "-"

        logger.log(tag, "[\(request.id)] \(request.method.rawValue) \(request.url) [\(headers)] [\(body)]")
    }

    func onSuccess(_ responseCode: HttpStatusCode, for request: ApiRequest) {
        logger.log(tag, "[\(request.id)] \(responseCode)")
    }

    func onFailure(_ error: Error, for request: ApiRequest) {
        logger.log(tag, "[\(request.id)] Failed with error: \(error.localizedDescription)")
    }
}
