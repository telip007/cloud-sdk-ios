//
//  WebViewController.swift
//  CloudSDK
//
//  Created by Victoria Teufel on 20.04.18.
//  Copyright © 2018 PACE. All rights reserved.
//

import UIKit
import WebKit

public protocol WebViewControllerDelegate: class {
    func decidePolicy(_ controller: UIViewController, for navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
    func cancel()
}

class WebViewController: UIViewController {

    weak var delegate: WebViewControllerDelegate?

    var tintColor: UIColor? = UIColor.white {
        didSet {
            progressView.progressTintColor = tintColor
            toolBar.tintColor = tintColor
        }
    }

    var webView: WKWebView!
    let toolBar = UIToolbar()
    private var progressView = UIProgressView()
    private var progressObservation: NSKeyValueObservation?

    private let backBarButtonItem = UIBarButtonItem(image: UIImage(named: "back", in: Bundle(for: WebViewController.self), compatibleWith: nil),
                                                    style: .plain,
                                                    target: self,
                                                    action: #selector(goBack))
    private let forwardBarButtonItem = UIBarButtonItem(image: UIImage(named: "forward", in: Bundle(for: WebViewController.self), compatibleWith: nil),
                                                       style: .plain,
                                                       target: self,
                                                       action: #selector(goForward))
    private let reloadBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reload))
    private let stopBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(stop))

    deinit {
        progressObservation?.invalidate()
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        addToolbar()
        addWebView()
        addProgressView()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var safeAreaInsets = UIEdgeInsets.zero

        if #available(iOS 11.0, *) {
           safeAreaInsets = self.view.safeAreaInsets
        }

        let toolBarHeight: CGFloat = 44
        toolBar.frame = CGRect(x: 0, y: view.frame.height - toolBarHeight - safeAreaInsets.bottom, width: view.frame.width, height: toolBarHeight)

        let webViewHeight = view.frame.height - toolBarHeight - safeAreaInsets.bottom  - safeAreaInsets.top
        webView.frame = CGRect(x: 0, y: safeAreaInsets.top, width: view.frame.width, height: webViewHeight)

        if let navigationBar = navigationController?.navigationBar {
            progressView.frame = CGRect(x: 0,
                                        y: navigationBar.frame.height - progressView.frame.height,
                                        width: navigationBar.frame.width,
                                        height: progressView.frame.height)
        }

        addBarButtonItems()
    }

    private func addToolbar() {
        toolBar.isOpaque = false
        view.addSubview(toolBar)
    }

    private func addWebView() {
        let configuration = WKWebViewConfiguration.init()

        if #available(iOS 11.0, *) {
            configuration.setURLSchemeHandler(self, forURLScheme: "paceapp")
        }

        webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.isMultipleTouchEnabled = true
        webView.isOpaque = true
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear

        automaticallyAdjustsScrollViewInsets = false

        view.addSubview(webView)

        progressObservation = webView.observe(\.estimatedProgress) { _, _ in
            let estimatedProgress = self.webView.estimatedProgress
            self.progressView.alpha = 1
            self.progressView.setProgress(Float(estimatedProgress), animated: true)

            if estimatedProgress >= 1.0 {
                UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseOut, animations: {
                    self.progressView.alpha = 0
                }, completion: { _ in
                    self.progressView.setProgress(0, animated: false)
                })
            }
        }
    }

    private func addProgressView() {
        progressView.trackTintColor = .clear
        navigationController?.navigationBar.addSubview(progressView)
    }

    private func addBarButtonItems() {
        guard toolBar.items?.isEmpty ?? true else { return }
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))

        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        toolBar.setItems([backBarButtonItem, flexibleSpace, forwardBarButtonItem, flexibleSpace, flexibleSpace, reloadBarButtonItem], animated: false)
    }

    private func updateBarButtonItems() {
        backBarButtonItem.isEnabled = webView.canGoBack
        forwardBarButtonItem.isEnabled = webView.canGoForward

        let updateReloadBarButtonItem: (UIBarButtonItem, Bool) -> UIBarButtonItem = { [unowned self] barButtonItem, isLoading in
            switch barButtonItem {
            case self.reloadBarButtonItem, self.stopBarButtonItem:
                return isLoading ? self.stopBarButtonItem : self.reloadBarButtonItem

            default:
                break
            }

            return barButtonItem
        }

        let isLoading = webView.isLoading
        toolbarItems = toolbarItems?.map { barButtonItem -> UIBarButtonItem in
            return updateReloadBarButtonItem(barButtonItem, isLoading)
        }
    }

    func load(request: URLRequest) {
        webView.load(request)
    }

    // MARK: - Actions

    @objc private func goBack() {
        webView.goBack()
    }

    @objc private func goForward() {
        webView.goForward()
    }

    @objc private func reload() {
        webView.stopLoading()
        webView.reload()
    }

    @objc private func stop() {
        webView.stopLoading()
    }

    @objc private func cancel() {
        delegate?.cancel()
    }

}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateBarButtonItems()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateBarButtonItems()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        updateBarButtonItems()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        updateBarButtonItems()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let delegate = delegate {
            delegate.decidePolicy(self, for: navigationAction, decisionHandler: decisionHandler)
        } else {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            if OAuthConnection.shared.open(url: url) {
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}

@available(iOS 11.0, *)
extension WebViewController: WKURLSchemeHandler {
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) { }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else { return }
        UIApplication.shared.open(url, options: [:]) { _ in }
    }
}
