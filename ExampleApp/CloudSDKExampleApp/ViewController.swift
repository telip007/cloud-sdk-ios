//
//  ViewController.swift
//  CloudSDKExampleApp
//
//  Created by Victoria Teufel on 28.03.18.
//  Copyright © 2018 PACE. All rights reserved.
//

import UIKit
import CloudSDK

class ViewController: UITableViewController {

    var webview: UIViewController?
    var tableItems: [Section] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false

        CloudSDK.shared.hasValidSession { hasValidSession in
            if hasValidSession {
                self.showLoggedInState()
            } else {
                self.showLoggedOutState()
            }
        }
    }

    private func showLoggedInState() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
        tableItems = [Section(title: "", rows: [Row(title: "Authorization Status", detail: "authorized")])]
        tableView.reloadData()
        getUserInfo()
    }

    private func showLoggedOutState() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Login", style: .plain, target: self, action: #selector(login))
        tableItems = [Section(title: "", rows: [Row(title: "Authorization Status", detail: "not authorized")])]
        tableView.reloadData()
    }

    @objc private func logout() {
        CloudSDK.shared.logout()
        self.showLoggedOutState()
    }

    @objc private func login() {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)

        let request = AuthorizationRequest(clientId: "a5e07401cf3fe1de54587e06a7037956be168e5273b8d4233079d9cb155ee4f7",
                                           clientSecret: "ba1d488447e8ee056d610b049ff3d6c078eeebd24889e40bdb2d23442b772cb1",
                                           redirectUrl: "pacetest://oauth",
                                           scope: "cockpit:*:* cloud:*:* poi:gas-stations:read")

        CloudSDK.shared.createSession(for: request, needsAuthentication: { webview in
            webview.tintColor = .black
            webview.barTintColor = .white
            self.webview = webview
            self.present(webview, animated: true, completion: nil)
        }, authenticated: {
            self.showLoggedInState()
            self.webview?.dismiss(animated: true) { self.webview = nil }
        }, failure: { error in
            self.showLoggedOutState()
            print(error)
            self.webview?.dismiss(animated: true) { self.webview = nil }
            self.handleLoginError()
        })
    }

    private func handleLoginError() {
        let alert = UIAlertController(title: "Error", message: "Login failed.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }

    private func getUserInfo() {
        CloudSDK.shared.getUserInfo(completion: { user in
            DispatchQueue.main.async {
                self.showUserData(user)
            }
        }, failure: { (_, _) in
            DispatchQueue.main.async {
                self.handleUserDataError()
            }
        })
    }

    private func showUserData(_ user: User) {
        tableItems = [
            Section(title: "", rows: [Row(title: "Authorization Status", detail: "authorized")]),
            Section(title: "User", rows: [
                Row(title: "E-Mail", detail: user.email),
                Row(title: "First Name", detail: user.firstName ?? "-"),
                Row(title: "Last Name", detail: user.lastName ?? "-"),
                Row(title: "UUID", detail: user.uuid),
                Row(title: "Gender", detail: user.gender ?? "-"),
                Row(title: "Birthday", detail: "\(user.birthday ?? "-")"),
                Row(title: "Mobile Number", detail: user.mobileNumber ?? "-"),
                Row(title: "Created At", detail: "\(Date(timeIntervalSince1970: Double(user.createdAt)))"),
                Row(title: "Onboarding Completed", detail: "\(user.onboardingCompleted)")
            ])
        ]
        tableView.reloadData()
    }

    private func handleUserDataError() {
        let alert = UIAlertController(title: "Error", message: "Could not load user data.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableItems.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableItems[section].rows.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableItems[section].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "cell")
        let tableItem = tableItems[indexPath.section].rows[indexPath.row]
        cell.textLabel?.text = tableItem.title
        cell.textLabel?.textColor = .gray
        cell.detailTextLabel?.text = tableItem.detail
        cell.detailTextLabel?.textColor = .black
        return cell
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
