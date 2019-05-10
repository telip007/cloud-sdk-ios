//
//  ApiError.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 21.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

public enum ApiError: Error {
    case invalidURL
    case requestFailed
    case unknownServerError
    case unknownHttpError(code: Int, message: String?)
    case httpError(code: Int, error: ApiErrorDetailsResponse?)

    init(code: Int?, data: Data?) {
        guard let code = code else {
            self = .unknownServerError
            return
        }

        guard let data = data, let errorObject = try? JSONDecoder.shared.decode(ApiErrorDetailsResponse.self, from: data) else {
            self = .httpError(code: code, error: nil)
            return
        }

        self = .httpError(code: code, error: errorObject)
    }
}

extension ApiError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Request url is malformed."

        case .requestFailed:
            return "The request failed due to unknown reasons."

        case .unknownServerError:
            return "Internal server error. Try again later."

        case let .unknownHttpError(code, message):
            return "Unknown http error (code: \(code), message: \(message ?? "-")."

        case let .httpError(code, error):
            return "Http error (code: \(code), details: \(error ?? ApiErrorDetailsResponse(errors: []))."
        }
    }
}
