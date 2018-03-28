//
//  HTTPRequest.swift
//  CloudSDK
//
//  Created by Victoria Teufel on 29.03.18.
//  Copyright © 2018 PACE. All rights reserved.
//

import Foundation

enum HTTPMethod {
    case get
    case post(Data?)

    func getValue() -> (String, Data?) {
        switch self {
        case .get:
            return ("GET", nil)

        case .post(let data):
            return ("POST", data)
        }
    }
}

protocol HTTPRequestRedirectionDelegate: class {
    func willPerformHTTPRedirection(response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void)
}

class HTTPRequest: NSObject {

    var session = URLSession(configuration: URLSessionConfiguration.default)
    static var baseURL = ""
    static var authenticationURL = ""

    weak var delegate: HTTPRequestRedirectionDelegate?

    override init() {
        super.init()
        session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    }

    func perform(path: String, method: HTTPMethod, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        guard let request = buildURLRequest(path: path, method: method) else {
            completion(nil, nil, nil)
            return
        }

        let task = session.dataTask(with: request, completionHandler: completion)
        task.resume()
    }

    private func buildURLRequest(path: String, method: HTTPMethod) -> URLRequest? {
        guard let url = URL(string: HTTPRequest.authenticationURL + path) else {
            return nil
        }

        let (httpMethod, bodyData) = method.getValue()

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        return request
    }

    func performAuthenticated(path: String, method: HTTPMethod, authToken: String, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        guard let request = buildURLRequest(path: path, method: method) else {
            completion(nil, nil, nil)
            return
        }

        performAuthenticated(request: request, authToken: authToken, completion: completion)
    }

    func performAuthenticated(request: URLRequest, authToken: String, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        var request = request
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        session.dataTask(with: request, completionHandler: completion).resume()
    }

}

extension HTTPRequest: URLSessionDataDelegate {

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        guard let delegate = delegate else {
            completionHandler(request)
            return
        }
        delegate.willPerformHTTPRedirection(response: response, newRequest: request, completionHandler: completionHandler)
    }

}
