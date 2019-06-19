//
//  RequestsViewController.swift
//  CloudSDKExampleApp
//
//  Created by Victoria Teufel on 28.03.18.
//  Copyright © 2018 PACE. All rights reserved.
//

import UIKit
import CloudSDK
import WebKit

class RequestsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    struct DemoRequest {
        let title: String
        let request: (RequestsViewController) -> Void
    }

    class DemoObjects {
        static let address = ApiRequest.AddressAttributes(street: "Haid-und-Neu-Str.", houseNo: "18", postalCode: "76131", city: "Karlsruhe", countryCode: "DE")
        static let sepaAttributes = ApiRequest.SepaAttributes(iban: "DE89 3704 0044 0532 0130 00",
                                                       title: "Prof. Dr.", firstName: "Jon", lastName: "Smith",
                                                       company: "Clean House GmbH", address: address)
        static let registerSepaDirectMethod = ApiRequest.RegisterSepaDirectMethodRequest(id: "2a1319c3-c136-495d-b59a-47b3246d08af", attributes: sepaAttributes)
    }

    let idHost = "{YOUR_ID_HOST_HERE}"
    let redirectUrl = "{YOUR_REDIRECT_URI_HERE}"
    let scope = "{YOUR_SCOPES_HERE}"
    let apiHost = "{YOUR_API_HOST_HERE}"
    let clientId = "{YOUR_CLIENT_ID_HERE}"

    var webview: UIViewController?
    var tableItems: [Section] = []

    var requests: [(category: String, requests: [DemoRequest])] = [
        ("Poi", [
            DemoRequest(title: "QueryLocationBasedApps", request: { $0.demoRequest(request: .queryLocationBasedApps(latitude: 48.7840031, longitude: 8.1943317), expect: ApiRequest.QueryLocationBasedAppsResponse.self) }),
            DemoRequest(title: "GetLocationBasedAppById", request: { $0.demoRequest(request: .getLocationBasedApp(byId: "2a1319c3-c136-495d-b59a-47b3246d08af"), expect: ApiRequest.GetLocationBasedAppResponse.self) }),
        ]),
        ("Pay", [
            DemoRequest(title: "GetAllPaymentMethods", request: { $0.demoRequest(request: .getAllPaymentMethods(), expect: ApiRequest.GetAllPaymentMethodsResponse.self) }),
            DemoRequest(title: "GetReadyPaymentMethods", request: { $0.demoRequest(request: .getReadyPaymentMethods(), expect: ApiRequest.GetAllPaymentMethodsResponse.self) }),
            DemoRequest(title: "GetPreAuthorizedPaymentMethods", request: { $0.demoRequest(request: .getPreAuthorizedPaymentMethods(), expect: ApiRequest.GetAllPaymentMethodsWithPreAuthorizedResponse.self) }),
            DemoRequest(title: "RegisterSepaDirectMethod", request: { $0.demoRequest(request: .registerSepaDirectMethod(body: DemoObjects.registerSepaDirectMethod), expect: ApiRequest.RegisterSepaDirectMethodResponse.self) }),
            DemoRequest(title: "DeletePaymentMethod", request: { $0.demoRequest(request: .deletePaymentMethod(paymentMethodId: DemoObjects.registerSepaDirectMethod.data.id), expect: ApiRequest.QueryLocationBasedAppsResponse.self) }),
        ])
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        let config = OAuthConnection.Configuration(clientId: clientId)
        config.idHost = idHost
        OAuthConnection.setup(configuration: config)

        if OAuthConnection.shared.authorizedSession {
            self.showLoggedInState()
        } else {
            self.showLoggedOutState()
        }

        OAuthConnection.shared.delegate = self
    }

    private func showLoggedInState() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout)),
        ]

    }

    private func showLoggedOutState() {
        navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Login", style: .plain, target: self, action: #selector(login))]
    }

    @objc private func logout() {
        OAuthConnection.shared.reset()
        self.showLoggedOutState()
    }

    @objc private func login() {
        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)

        OAuthConnection.shared.authorize(clientId: clientId, redirectUrl: redirectUrl, scope: scope) { result in
            switch result {
            case .success(let data):
                OAuthConnection.shared.exchange(withHost: self.idHost, clientId: self.clientId, redirectUrl: self.redirectUrl, code: data) { tokens in
                    switch tokens {
                    case .success(let token):
                        self.showLoggedInState()

                    case .failure(let error):
                        break
                    }
                }

            case .failure(let error):
                break
            }
        }
    }

    private func handleLoginError() {
        let alert = UIAlertController(title: "Error", message: "Login failed.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }

    private func demoRequest<T: Codable>(request: ApiRequest, expect: T.Type) {
        request.host = apiHost
        OAuthConnection.shared.request(request, expect: T.self) { result in
            var title = ""
            var message = ""
            let style: UIAlertController.Style = .alert

            switch result {
            case .failure(let error):
                title = "Failure"
                message = error.localizedDescription
                break

            case .success(let response):
                title = "Success"
                message = "\(response.code)\n"

                if let object = response.object {
                    let encoded = String(data: try! JSONEncoder().encode(object), encoding: .utf8)!
                    message += encoded
                }

                break
            }

            DispatchQueue.main.async {
                let controller = UIAlertController(title: title, message: message, preferredStyle: style)
                controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(controller, animated: true, completion: nil)
            }
        }
    }

    private func handleUserDataError() {
        let alert = UIAlertController(title: "Error", message: "Could not load user data.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return requests.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requests[section].requests.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return requests[section].category
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "cell")
        let tableItem = requests[indexPath.section].requests[indexPath.row] as DemoRequest
        cell.textLabel?.text = tableItem.title
        cell.textLabel?.textColor = .gray
//        cell.detailTextLabel?.text = tableItem.detail
        cell.detailTextLabel?.textColor = .black
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tableItem = requests[indexPath.section].requests[indexPath.row] as DemoRequest
        tableItem.request(self)

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension RequestsViewController: OAuthConnectionDelegate {
    func oAuthSessionCreated(refreshToken: String, accessToken: String, scope: String, expirationDate: Int) {
        DispatchQueue.main.async {
            self.showLoggedInState()
        }
    }

    func oAuthSessionInvalid() {
        DispatchQueue.main.async {
            self.showLoggedOutState()
        }
    }

    func oAuthGrantConsentRequested(with url: URL) {
        DispatchQueue.main.async {
            let vc = AuthorizationWebViewController(url: url, delegate: self)
            self.present(vc, animated: true)
        }
    }
}

extension RequestsViewController: WebViewControllerDelegate {
    func cancel() {
        dismiss(animated: true) {
            self.showLoggedOutState()
        }
    }

    func decidePolicy(_ controller: UIViewController, for navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        if OAuthConnection.shared.open(url: url) {
            decisionHandler(.cancel)
            controller.dismiss(animated: true, completion: nil)
        } else {
            decisionHandler(.allow)
        }
    }
}

struct Section {
    let title: String
    let rows: [Row]
}

struct Row {
    let title: String
    let detail: String
}
