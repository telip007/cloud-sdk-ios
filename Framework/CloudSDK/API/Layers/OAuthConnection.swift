//
//  OAuthAuthorizationManager.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 10.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation
import WebKit

public protocol OAuthConnectionDelegate: class {
    /// A request was made, but the oauth session is not yet created or expired
    func oAuthSessionInvalid()

    /// A oauth session was successfully created.
    /// Note: This could be due to an active creation via `exchange` or the result of an automatic refresh
    func oAuthSessionCreated(refreshToken: String, accessToken: String, scope: String, expirationDate: Int)

    /// An oauth grant requests needs user input. Open the URL in a browser or the supplied `AuthorizationWebViewController`
    func oAuthGrantConsentRequested(with url: URL)
}

public protocol AuthorizationConnection {
    func request<T>(_ request: ApiRequest, expect: T.Type, then handler: @escaping (Result<ApiResponse<T>, Error>) -> Void) where T: Decodable
}

public class OAuthConnection {
    public class Configuration {
        public var idHost: String = Host.id.hostName
        public var clientId: String
        public var useNativeLogin = false

        public init(clientId: String) {
            self.clientId = clientId
        }
    }

    private struct RequestQueueItem {
        let retryHandler: () -> Void
        let cancelHandler: () -> Void
    }

    public static var shared: OAuthConnection = OAuthConnection()
    public weak var delegate: OAuthConnectionDelegate?
    public var authorizedSession: Bool {
        return datastore.currentOAuthSession != nil
    }

    public var scope: String? {
        return datastore.currentOAuthSession?.scope
    }

    public var accessToken: String? {
        return datastore.currentOAuthSession?.accessToken
    }

    private var configuration: Configuration!
    private var apiConnection: APIConnection!
    private var datastore: Datastore!

    private var authorizationBehavior: AuthorizationBehavior!

    private var codeChallenge: String!
    private var codeVerifier: String!

    private var runningAuthorizeRequest: ApiRequest?
    private var codeRedirectUrl: URL?

    private var refreshInProgress = false

    private var requestQueue = [RequestQueueItem]()

    private var requestHandlers: [String: RequestHandler] = [:]

    private struct RequestHandler {
        let execute: (String) -> Void
    }

    private init(configuration: Configuration? = nil, factory: Factory = DefaultFactory.shared) {
        self.datastore = factory.datastore
        self.authorizationBehavior = AuthorizationBehavior()
        self.configuration = configuration ?? Configuration(clientId: "")
        self.apiConnection = factory.apiConnection
        self.apiConnection.add(behavior: authorizationBehavior)
        self.apiConnection.delegate = self

        self.codeVerifier = PKCE.createCodeVerifier()
        self.codeChallenge = PKCE.createCodeChallenge(fromVerifier: self.codeVerifier)

        checkAndRefreshSession()
    }

    public static func setup(configuration: Configuration) {
        OAuthConnection.shared = OAuthConnection(configuration: configuration)
    }

    public func open(url: URL) -> Bool {
        codeRedirectUrl = nil

        if let code = extractCode(from: url), let state = url.state {
            codeRetrieved(code, with: state)
            return true
        }

        return false
    }

    private func extractCode(from url: URL) -> String? {
        guard let code = url.oAuthCode else { return nil }

        return code
    }

    public func authorize(host: String? = nil,
                          clientId: String? = nil,
                          redirectUrl: String,
                          scope: String,
                          codeChallenge: String? = nil,
                          then handler: @escaping (Result<String, Error>) -> Void) {
        let state = UUID().uuidString

        runningAuthorizeRequest = ApiRequest.authorize(host: host ?? configuration.idHost,
                                                       clientId: clientId ?? configuration.clientId,
                                                       redirectUrl: redirectUrl,
                                                       scope: scope,
                                                       codeChallenge: codeChallenge ?? self.codeChallenge,
                                                       state: state)
        request(runningAuthorizeRequest!, expect: EmptyResponse.self) { result in
            self.handleAuthorizationResult(result, handler, state)
        }
    }

    @available(*, deprecated, message: "This method is deprecated and should only be used, if native login has not been implemented.")
    public func authorize(host: String? = nil,
                          clientId: String? = nil,
                          redirectUrl: String,
                          scope: String,
                          codeChallenge: String? = nil,
                          userAuthToken: String,
                          deviceUUID: String,
                          then handler: @escaping (Result<String, Error>) -> Void) {
        let state = UUID().uuidString

        runningAuthorizeRequest = ApiRequest.authorize(host: host ?? configuration.idHost,
                                                       clientId: clientId ?? configuration.clientId,
                                                       redirectUrl: redirectUrl,
                                                       scope: scope,
                                                       codeChallenge: codeChallenge ?? self.codeChallenge,
                                                       userAuthToken: userAuthToken,
                                                       deviceUUID: deviceUUID,
                                                       state: state)
        request(runningAuthorizeRequest!, expect: EmptyResponse.self) { result in
            self.handleAuthorizationResult(result, handler, state)
        }
    }

    private func handleAuthorizationResult(_ result: Result<ApiResponse<EmptyResponse>, Error>, _ handler: @escaping (Result<String, Error>) -> Void, _ state: String) {
        var completionHandler: ((String) -> Void)?

        switch result {
        case .failure(let failure):
            handler(.failure(failure))

        case .success(let success):
            if success.code == .redirect {
                completionHandler = { code in handler(.success(code)) }
            } else {
                handler(.failure(ApiError.httpError(code: success.code.rawValue, error: ApiErrorDetailsResponse(errors: []))))
            }
        }

        if let completion = completionHandler {
            let requestHandler = RequestHandler(execute: completion)

            self.requestHandlers[state] = requestHandler
        }

        if let url = codeRedirectUrl {
            _ = open(url: url)
        }
    }

    public func exchange(withHost host: String? = nil,
                         clientId: String? = nil,
                         redirectUrl: String,
                         code: String,
                         codeVerifier: String? = nil,
                         persistTokens: Bool = true,
                         then handler: @escaping (Result<ApiRequest.TokenResponseData, Error>) -> Void) {
        let exchangeRequest = ApiRequest.token(host: host ?? configuration.idHost,
                                               accessTokenData: ApiRequest.AccessTokenData(clientId: clientId ?? configuration.clientId,
                                                                                           redirectUri: redirectUrl,
                                                                                           code: code,
                                                                                           codeVerifier: codeVerifier ?? self.codeVerifier))

        request(exchangeRequest, expect: ApiRequest.TokenResponseData.self) { [weak self] result in
            switch result {
            case .success(let response):
                guard let self = self, let tokens = response.object, response.code == .ok else {
                    return
                }

                if persistTokens {
                    let encoded = tokens.encode(with: JSONEncoder.shared)!
                    self.datastore.setData(encoded, forKey: self.datastore.OAuthSessionKey)
                    self.sessionCreated(tokens)
                }

                handler(.success(tokens))

            case .failure(let error):
                handler(.failure(error))
            }
        }
    }

    public func refreshTokens() {
        checkAndRefreshSession()
    }

    public func reset() {
        revokeKey { [weak self] _ in
            guard let self = self else { return }

            self.datastore.delete(self.datastore.OAuthSessionKey)
            self.authorizationBehavior.set(tokenData: nil)
            self.cleanupWebsiteData()
        }
    }

    private func cleanupWebsiteData() {
        DispatchQueue.main.async { // WKProcessPool must to accessed from the main thread
            WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                records.forEach { record in
                    WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                }
            }

            HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        }
    }

    private func checkAndRefreshSession() {
        guard let session = datastore.currentOAuthSession else {
            delegate?.oAuthSessionInvalid()
            return
        }

        authorizationBehavior.set(tokenData: session)

        if !session.isValid {
            refreshSession(session)
        } else {
            delegate?.oAuthSessionCreated(refreshToken: session.refreshToken,
                                          accessToken: session.accessToken,
                                          scope: session.scope,
                                          expirationDate: session.createdAt + session.expiresIn)
        }
    }

    private func refreshSessionOrFail() {
        guard let session = datastore.currentOAuthSession else {
            delegate?.oAuthSessionInvalid()
            return
        }

        refreshSession(session)
    }

    private func refreshSession(_ session: ApiRequest.TokenResponseData) {
        guard !refreshInProgress else { return }

        refreshInProgress = true

        let data = ApiRequest.RefreshTokenData(clientId: configuration.clientId, refreshToken: session.refreshToken)
        let tokenRequest = ApiRequest.token(host: configuration.idHost, refreshTokenData: data)

        request(tokenRequest, expect: ApiRequest.TokenResponseData.self) { [weak self] result in
            switch result {
            case .failure(let error):
                if case let ApiError.httpError(code, _) = error, code == HttpStatusCode.unauthorized.rawValue {
                    self?.datastore.currentOAuthSession = nil
                    self?.sessionExpired()
                }

            case .success(let response):
                if let session = response.object, response.code == .ok {
                    self?.datastore.currentOAuthSession = response.object
                    self?.sessionCreated(session)
                } else {
                    // Unknown failure. Try again later?
                    //self?.sessionExpired()
                }
            }

            self?.refreshInProgress = false
        }
    }

    private func sessionCreated(_ session: ApiRequest.TokenResponseData) {
        authorizationBehavior.set(tokenData: session)

        let localCopy = requestQueue
        requestQueue.removeAll()
        localCopy.forEach { $0.retryHandler() }

        delegate?.oAuthSessionCreated(refreshToken: session.refreshToken,
                                      accessToken: session.accessToken,
                                      scope: session.scope,
                                      expirationDate: session.createdAt + session.expiresIn)
    }

    private func sessionExpired() {
        let localCopy = requestQueue
        requestQueue.removeAll()
        localCopy.forEach { $0.cancelHandler() }

        delegate?.oAuthSessionInvalid()
    }

    private func codeRetrieved(_ code: String, with state: String) {
        guard let handler = requestHandlers[state] else { return }

        handler.execute(code)
        requestHandlers.removeValue(forKey: state)
    }

    private func revokeKey(completion: ((Bool) -> Void)? = nil) {
        guard let session = datastore.currentOAuthSession else {
            delegate?.oAuthSessionInvalid()

            completion?(false)
            return
        }

        let data = ApiRequest.RevokeTokenData(clientId: configuration.clientId, accessToken: session.accessToken)
        let revokeRequest = ApiRequest.revoke(host: configuration.idHost, revokeTokenData: data)

        request(revokeRequest, expect: EmptyResponse.self) { result in
            switch result {
            case .success(let response):
                guard response.code == .ok else {
                    completion?(false)
                    return
                }

                completion?(true)

            case .failure:
                completion?(false)
            }
        }
    }
}

extension OAuthConnection: AuthorizationConnection {
    public func request<T>(_ request: ApiRequest, expect: T.Type, then handler: @escaping (Result<ApiResponse<T>, Error>) -> Void) where T: Decodable {
        guard !request.bypassAuthentication else {
            apiConnection.request(request, expect: T.self, then: handler)
            return
        }

        guard let session = datastore.currentOAuthSession else {
            delegate?.oAuthSessionInvalid()
            return
        }

        let requestQueueItem = RequestQueueItem(retryHandler: {
            self.request(request, expect: T.self, then: handler)
        }, cancelHandler: {
            handler(.failure(ApiError.requestFailed))
        })

        guard session.isValid else {
            requestQueue.append(requestQueueItem)
            checkAndRefreshSession()
            return
        }

        apiConnection.request(request, expect: T.self, then: { [weak self] result in
            switch result {
            case .failure(let error):
                if case let ApiError.httpError(code, _) = error, code == HttpStatusCode.unauthorized.rawValue && !request.bypassAuthentication {
                    self?.requestQueue.append(requestQueueItem)
                    self?.refreshSessionOrFail()
                } else if case let ApiError.httpError(code, _) = error, code == HttpStatusCode.forbidden.rawValue {
                    handler(.failure(ApiError.forbidden))
                } else {
                    handler(.failure(error))
                }

            case .success(let response):
                handler(.success(response))
            }
        })
    }
}

extension OAuthConnection: APIConnectionDelegate {
    public func apiConnectionShouldFollowRedirect(request: ApiRequest, to: URL?) -> Bool {
        if let to = to, runningAuthorizeRequest == request {
            // We either open a web based loginview
            // or when provided, a native login
            if extractCode(from: to) != nil {
                codeRedirectUrl = to
            } else {
                delegate?.oAuthGrantConsentRequested(with: to)
            }

            return false
        }

        return true
    }
}

extension Datastore {
    var OAuthSessionKey: String { return "oauthconnection.OAuthSessionKey" }
    var currentOAuthSession: ApiRequest.TokenResponseData? {
        get { return try? getData(OAuthSessionKey)?.decode(contentType: .json) as ApiRequest.TokenResponseData? }
        set {
            guard let value = newValue, let encoded = value.encode(with: JSONEncoder.shared) else { return }
            setData(encoded, forKey: OAuthSessionKey)
        }
    }
}
