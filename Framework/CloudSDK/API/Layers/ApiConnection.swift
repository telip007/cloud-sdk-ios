//
//  API.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 09.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

public protocol APIConnectionDelegate: class {
    func apiConnectionShouldFollowRedirect(request: ApiRequest, to: URL?) -> Bool
}

public protocol APIConnection {
    var delegate: APIConnectionDelegate? { get set }
    func request<T>(_ request: ApiRequest, expect: T.Type, then handler: @escaping (Result<ApiResponse<T>, Error>) -> Void) where T: Decodable
    func add(behavior: ApiRequestBehavior)
}

public class ApiConnection: APIConnection {
    private var behaviors: [ApiRequestBehavior]
    private var httpConnection: HttpConnection

    private var requestIds = [Int: ApiRequest]()

    public weak var delegate: APIConnectionDelegate?

    init(factory: Factory) {
        self.behaviors = [LoggingBehavior(factory: factory)]
        self.httpConnection = factory.httpConnection
        self.httpConnection.delegate = self
    }

    public func add(behavior: ApiRequestBehavior) {
        self.behaviors.append(behavior)
    }

    public func request<T>(_ request: ApiRequest, expect: T.Type, then handler: @escaping (Result<ApiResponse<T>, Error>) -> Void) where T: Decodable {
        behaviors.forEach { request.headers = request.headers + $0.headers }
        behaviors.forEach { $0.beforeSend(request: request) }

        let requestId = httpConnection.execute(request: request.networkRequest) { [weak self] response in
            switch response {
            case .failure(let failure):
                handler(.failure(failure))

            case .success(let response):
                guard let statusCode = HttpStatusCode(from: response.statusCode), !statusCode.error else {
                    let error = ApiError(code: response.statusCode, data: response.data)
                    self?.behaviors.forEach { $0.onFailure(error, for: request) }
                    handler(.failure(error))
                    return
                }

                if statusCode.redirect {
                    handler(.success(ApiResponse<T>(code: statusCode, object: nil)))
                    return
                }

                var successResponse = ApiResponse<T>(code: statusCode, object: nil)

                do {
                    if let data = response.data, data.count > 0 {
                        let decoded: T? = try data.decode(contentType: request.contentType)
                        successResponse.object = decoded
                    }
                } catch {
                    self?.behaviors.forEach { $0.onFailure(error, for: request) }
                    handler(.failure(error))
                    return
                }

                self?.behaviors.forEach { $0.onSuccess(successResponse.code, for: request) }
                handler(.success(successResponse))

            }
        }

        requestIds.updateValue(request, forKey: requestId)
    }
}

extension ApiConnection: HttpConnectionDelegate {
    public func httpConnectionShouldFollowRedirect(requestId: Int, to: URL?) -> Bool {
        guard let request = requestIds[requestId] else { fatalError("No request for redirect found") }
        return delegate?.apiConnectionShouldFollowRedirect(request: request, to: to) ?? true
    }
}
