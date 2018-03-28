//
//  OAuthManager.swift
//  CloudSDK
//
//  Created by Victoria Teufel on 29.03.18.
//  Copyright © 2018 PACE. All rights reserved.
//

import Foundation
import WebKit
import SafariServices

class OAuthManager: NSObject {

    let httpRequest = HTTPRequest()
    let authRequest: AuthorizationRequest
    let needsAuthentication: (AuthorizationWebViewController) -> Void
    let authenticated: (Session) -> Void
    let failure: (PACEAuthenticationError) -> Void

    var isAuthenticated = false

    init(authRequest: AuthorizationRequest,
         needsAuthentication: @escaping (AuthorizationWebViewController) -> Void,
         authenticated: @escaping (Session) -> Void,
         failure: @escaping (PACEAuthenticationError) -> Void) {
        self.authRequest = authRequest
        self.needsAuthentication = needsAuthentication
        self.authenticated = authenticated
        self.failure = failure

        super.init()

        httpRequest.delegate = self

        Keychain.oAuthApplication = authRequest
    }

    func createSession() {
        httpRequest.perform(path: "oauth2/authorize?\(buildUrlParams(from: authRequest.authorizationParams))", method: .get) { (_, response, error) in
            DispatchQueue.main.async {
                self.handle(authorizationResponse: response, error: error)
            }
        }
    }

    private func buildUrlParams(from urlParams: [String: String]) -> String {
        return urlParams
            .map { $0.key + "=" + $0.value }
            .joined(separator: "&")
    }

    private func handle(authorizationResponse response: URLResponse?, error: Error?) {
        guard !isAuthenticated else {
            return
        }

        guard let response = response as? HTTPURLResponse, response.statusCode == 200, let url = response.url else {
            self.failure(.serverError(error))
            return
        }

        if isRedirectUrl(url), let code = extractCode(from: url) {
            self.didAuthenticate(code)
            return
        }

        guard let authUrl = URL(string: HTTPRequest.authenticationURL + "oauth2/authorize?\(buildUrlParams(from: authRequest.authorizationParams))") else {
            self.failure(.serverError(error))
            return
        }

        let cookie = response.allHeaderFields["Set-Cookie"] as? String
        self.needsAuthentication(AuthorizationWebViewController(url: authUrl, cookie: cookie, delegate: self))
    }

    private func isRedirectUrl(_ url: URL) -> Bool {
        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let redirectURLComponents = URLComponents(string: authRequest.redirectUrl),
            urlComponents.host == redirectURLComponents.host {
            return true
        }
        return false
    }

    private func extractCode(from url: URL) -> String? {
        return URLComponents(url: url, resolvingAgainstBaseURL: true)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value
    }

    private func didAuthenticate(_ code: String) {
        var body = authRequest.accessTokenParams
        body["code"] = code
        let data = try? JSONEncoder().encode(body)

        httpRequest.perform(path: "oauth2/token", method: .post(data)) { (data, response, error) in
            DispatchQueue.main.async {
                self.handle(authenticationResponse: response, data: data, error: error)
            }
        }
    }

    private func handle(authenticationResponse response: URLResponse?, data: Data?, error: Error?) {
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            failure(.serverError(error))
            return
        }

        if let data = data, let session = try? JSONDecoder().decode(Session.self, from: data) {
            self.authenticated(session)
        }
    }

}

extension OAuthManager: WebViewControllerDelegate {

    func decidePolicy(for navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url, isRedirectUrl(url) else {
            decisionHandler(.allow)
            return
        }

        self.isAuthenticated = true
        if let code = extractCode(from: url) {
            self.didAuthenticate(code)
        } else {
            self.failure(.cancelled)
        }

        decisionHandler(.cancel)
    }

    func cancel() {
        if !self.isAuthenticated {
            self.failure(.cancelled)
        }
    }

}

extension OAuthManager: HTTPRequestRedirectionDelegate {

    func willPerformHTTPRedirection(response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        guard let url = request.url, isRedirectUrl(url) else {
            completionHandler(request)
            return
        }

        DispatchQueue.main.async {
            self.isAuthenticated = true
            if let code = self.extractCode(from: url) {
                self.didAuthenticate(code)
            } else {
                self.failure(.cancelled)
            }

            completionHandler(nil)
        }
    }

}
