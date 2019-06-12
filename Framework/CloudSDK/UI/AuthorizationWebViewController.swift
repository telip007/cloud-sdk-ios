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

    public init(url: URL, delegate: WebViewControllerDelegate?) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
        webView.delegate = delegate
        setViewControllers([webView], animated: false)
        webView.title = "PACE"
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

        let request = URLRequest(url: url)

        webView.load(request: request)
    }
}
