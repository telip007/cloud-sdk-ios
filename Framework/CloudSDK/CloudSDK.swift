//
//  CloudSDK.swift
//  CloudSDK
//
//  Created by Victoria Teufel on 29.03.18.
//  Copyright © 2018 PACE. All rights reserved.
//

import UIKit

/// PACE Cloud Environment
public class PACECloudEnvironment {
    /// base url for API requests
    public let baseUrl: String

    /// base url for authentication
    public let authenticationURL: String

    /// Instantiates a new environemnt with a base url for api communication and a authentication url
    public init(baseUrl: String, authenticationURL: String) {
        self.baseUrl = baseUrl
        self.authenticationURL = authenticationURL
    }

    /// production environment
    public static let production = PACECloudEnvironment(baseUrl: "https://api.pace.cloud/", authenticationURL: "https://id.pace.cloud/")

    public static let development = PACECloudEnvironment(baseUrl: "https://api.pace.cloud/", authenticationURL: "https://cp-1-dev.pacelink.net/")
}

/// Authentication error object
public enum PACEAuthenticationError: Error {
    /// no session available
    case noSession
    /// authentication was cancelled
    case cancelled
    /// server error
    case serverError(Error?)
    /// request url is not targeting PACE API
    case noPaceApiRequest
}

///  Provides an interface for OAuth and authenticated request to the PACE Backend
public class CloudSDK {

    /// Singleton instance of CloudSDK
    public static let shared = CloudSDK()

    /// Current Cloud environment, default: .production
    public var environment: PACECloudEnvironment = .production {
        didSet {
            HTTPRequest.baseURL = environment.baseUrl
            HTTPRequest.authenticationURL = environment.authenticationURL
        }
    }

    var currentSession: Session? {
        didSet {
            if currentSession != nil {
                Keychain.userAuthToken = currentSession
            }
        }
    }
    var isRefreshingSession = false
    var authManager: OAuthManager?
    let httpRequest = HTTPRequest()
    var requestQueue = [RequestQueueItem]()

    private init() {
        currentSession = Keychain.userAuthToken
    }

    /**
     Setup PACE Cloud Environment.
     Has to be called before requesting authorization or performing requests.
     Defaults to .production
     */
    public func setup(environment: PACECloudEnvironment) {
        self.environment = environment
    }

    // MARK: - Session
    /**
     Request OAuth authorization for PACE
     - parameter authRequest: authorization information
     - parameter needsAuthentication: callback containing a AuthorizationWebViewController if the user needs to grant authorization, present this in your app
     - parameter authenticated: user authenticated successfully
     - parameter failure: authentication failed
     */
    public func createSession(for authRequest: AuthorizationRequest,
                              needsAuthentication: @escaping (AuthorizationWebViewController) -> Void,
                              authenticated: @escaping () -> Void,
                              failure: @escaping (PACEAuthenticationError) -> Void) {
        logout()

        initializeAuthManager(authRequest, needsAuthentication, authenticated, failure)

        authManager?.createSession()
    }

    /// Logout and destroy the current session
    public func logout() {
        Keychain.oAuthApplication = nil
        Keychain.userAuthToken = nil
        currentSession?.invalidate()
        currentSession = nil
    }

    private func initializeAuthManager(_ authRequest: AuthorizationRequest, _ needsAuthentication: @escaping (AuthorizationWebViewController) -> Void,
                                       _ authenticated: @escaping () -> Void, _ failure: @escaping (PACEAuthenticationError) -> Void) {
        authManager = OAuthManager(authRequest: authRequest, needsAuthentication: needsAuthentication, authenticated: { session in
            self.currentSession = session
            authenticated()
            self.authManager = nil
        }, failure: { error in
            failure(error)
            self.authManager = nil
        })
    }

    /**
     Checks if a valid session exists
     - parameter completion: true if a valid session exists, false if not
     */
    public func hasValidSession(_ completion: @escaping (Bool) -> Void) {
        getUserInfo(completion: { _ in
            DispatchQueue.main.async {
                completion(true)
            }
        }, failure: { (_, _) in
            DispatchQueue.main.async {
                completion(false)
            }
        })
    }

    /**
     Get short lived session token
     - parameter completion: contains short lived session token if it exists and is valid
     */
    public func getSessionToken(_ completion: @escaping(String?) -> Void) {
        self.hasValidSession { hasValidSessionToken in
            if hasValidSessionToken {
                completion(self.currentSession?.accessToken)
            } else {
                completion(nil)
            }
        }
    }

    // MARK: - Requests

    /**
     Perform an authenticated request if a valid session exists
     - if the request does not target the PACE API the request is not executed and the completion contains PACEAuthenticationError.noPaceApiRequest
     - if no session exists the completion contains PACEAuthenticationError.noSession error
     - if the session is expired it is renewed automatically

     - parameter request: request to perform
     - parameter completion: contains the data, response and error of the executed request
     */
    public func perform(request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        guard urlNeedAuthentication(request.url) else {
            completion(nil, nil, PACEAuthenticationError.noPaceApiRequest)
            return
        }

        perform(request: request, completion: completion, tryRefresh: true)
    }

    private func urlNeedAuthentication(_ url: URL?) -> Bool {
        guard let host = url?.host,
            let baseURLHost = URL(string: environment.baseUrl)?.host,
            let authenticationURLHost = URL(string: environment.authenticationURL)?.host else {
                return false
        }
        return baseURLHost == host || authenticationURLHost == host
    }

    private func perform(request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void, tryRefresh: Bool) {
        let requestItem = RequestQueueItem(request: request, completion: completion)
        guard !isRefreshingSession else {
            requestQueue.append(requestItem)
            return
        }

        guard let session = currentSession else {
            completion(nil, nil, PACEAuthenticationError.noSession)
            return
        }

        httpRequest.performAuthenticated(request: request, authToken: session.accessToken) { (data, response, error) in
            if let response = response as? HTTPURLResponse, response.statusCode == 401, tryRefresh {
                self.refresh(session: session, requestItem: requestItem)
                return
            }

            completion(data, response, error)
        }
    }

    private func refresh(session: Session, requestItem: RequestQueueItem) {
        DispatchQueue.main.async {
            guard !self.isRefreshingSession else {
                self.requestQueue.append(requestItem)
                return
            }

            self.isRefreshingSession = true
            session.refresh { newSession in
                DispatchQueue.main.async {
                    if newSession != nil {
                        self.currentSession = newSession
                    }
                    self.isRefreshingSession = false
                    self.requestQueue.append(requestItem)
                    self.emptyRequestQueue()
                }
            }
        }
    }

    private func emptyRequestQueue() {
        requestQueue.forEach { perform(request: $0.request, completion: $0.completion, tryRefresh: false) }
        requestQueue.removeAll()
    }

    /**
     Get user info from authenticated user
     - parameter completion: contains user information
     - parameter failure: request failed with error or status code
     */
    public func getUserInfo(completion: @escaping (User) -> Void, failure: @escaping (Error?, Int?) -> Void) {
        guard let url = URL(string: environment.authenticationURL)?.appendingPathComponent("oauth2/me") else {
            failure(nil, nil)
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        perform(request: request) { (data, response, error) in
            guard let response = response as? HTTPURLResponse else {
                failure(error, nil)
                return
            }

            guard response.statusCode == 200,
                let data = data,
                let userResponse = try? JSONDecoder().decode(UserResponse.self, from: data) else {
                    failure(error, response.statusCode)
                    return
            }

            completion(userResponse.user)
        }
    }
}
