//
//  AuthorizationWebViewController.swift
//  CloudSDK
//
//  Created by Victoria Teufel on 28.03.18.
//  Copyright © 2018 PACE. All rights reserved.
//

import UIKit
import WebKit

/// View Controller for requesting the users authorization for OAuth
public class AuthorizationWebViewController: UINavigationController {
    let url: URL
    let cookie: String?

    /// Tint color for title label and buttons
    public var tintColor: UIColor? {
        didSet {
            webView.tintColor = tintColor
            navigationBar.tintColor = tintColor
            navigationBar.titleTextAttributes = [.foregroundColor: tintColor as Any]
        }
    }

    /// tint color for navigation and toolbar
    public var barTintColor: UIColor? {
        didSet {
            navigationBar.barTintColor = barTintColor
            webView.toolBar.barTintColor = barTintColor
        }
    }

    private let webView = WebViewController()

    init(url: URL, cookie: String?, delegate: WebViewControllerDelegate) {
        self.url = url
        self.cookie = cookie
        super.init(nibName: nil, bundle: nil)
        self.webView.delegate = delegate
        self.setViewControllers([webView], animated: false)
        self.webView.title = "PACE"
    }

    /// :nodoc:
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// :nodoc:
    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
    }

    /// :nodoc:
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        var request = URLRequest(url: url)
        if let cookie = self.cookie {
            request.setValue(cookie, forHTTPHeaderField: "Cookie")
        }

        webView.load(request: request)
    }
}
