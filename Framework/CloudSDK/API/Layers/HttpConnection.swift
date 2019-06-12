//
//  NetworkSession.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 09.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

public protocol HttpConnectionDelegate: class {
    func httpConnectionShouldFollowRedirect(requestId: Int, to: URL?) -> Bool
}

public struct HttpRequest {
    let url: URL
    let body: Data?
    let method: HttpRequestMethod
    let headers: [String: String]?
}

public enum HttpRequestMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

public protocol HttpConnection {
    var delegate: HttpConnectionDelegate? { get set }

    func execute(request: HttpRequest, completionHandler: @escaping (Result<NetworkResponse, Error>) -> Void) -> Int
}

public struct NetworkResponse {
    let data: Data?
    let statusCode: Int?
}

public class URLHttpConnection: NSObject, HttpConnection {
    public static let shared = URLHttpConnection()

    public weak var delegate: HttpConnectionDelegate?
    var session: URLSession!

    public override init() {
        super.init()

        // Set cookie policies.
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpShouldSetCookies = false

        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    public func execute(request: HttpRequest, completionHandler: @escaping (Result<NetworkResponse, Error>) -> Void) -> Int {
        var urlRequest = URLRequest(url: request.url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30.0) // TODO: Config?

        urlRequest.httpBody = request.body
        urlRequest.httpMethod = request.method.rawValue
        request.headers?.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }

        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                completionHandler(.failure(error))
            } else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode
                completionHandler(.success(NetworkResponse(data: data, statusCode: statusCode)))
            }
        }

        task.resume()
        return task.taskIdentifier
    }
}

extension URLHttpConnection: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           willPerformHTTPRedirection response: HTTPURLResponse,
                           newRequest request: URLRequest,
                           completionHandler: @escaping (URLRequest?) -> Void) {

        var newRequest = request

        // URLSession removes auth headers from redirects, copy them over
        if let authHeaderValue = task.originalRequest?.value(forHTTPHeaderField: "Authorization") {
            newRequest.setValue(authHeaderValue, forHTTPHeaderField: "Authorization")
        }

        guard let delegate = delegate else {
            completionHandler(nil)
            return
        }

        if delegate.httpConnectionShouldFollowRedirect(requestId: task.taskIdentifier, to: newRequest.url) {
            completionHandler(newRequest)
        } else {
            completionHandler(nil)
        }
    }
}
