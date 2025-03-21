//
//  WebViewViewController.swift
//  Image_Feed
//
//  Created by Yura on 06.02.25.
//

import UIKit
@preconcurrency import WebKit

final class WebViewViewController: UIViewController, WebViewViewControllerProtocol {
    
    var presenter: WebViewPresenterProtocol?
    
    @IBOutlet var webView: WKWebView!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet weak var backButton: UIButton!
    
    weak var delegate: WebViewViewControllerDelegate?
    
    private var progressObservation: NSKeyValueObservation?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter?.viewDidLoad()
        webView.navigationDelegate = self
        loadAuthView()
        
        progressObservation = webView.observe(
            \WKWebView.estimatedProgress,
             options: [.new],
             changeHandler: { [weak self] _, _ in
                 guard let self = self else { return }
                 presenter?.didUpdateProgressValue(webView.estimatedProgress)
             }
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        progressObservation?.invalidate()
    }
    
    // MARK: - Actions
    @IBAction func backButtonTapped(_ sender: Any) {
        delegate?.webViewViewControllerDidCancel(self)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Private Methods
    private func loadAuthView() {
    }
    
    func setProgressValue(_ newValue: Float) {
        progressView.progress = newValue
    }
    
    func setProgressHidden(_ isHidden: Bool) {
        progressView.isHidden = isHidden
    }
    
    func load(request: URLRequest) {
        webView.load(request)
    }
}

// MARK: - WKNavigationDelegate
extension WebViewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            print("Перенаправление на URL: \(url.absoluteString)")
            if let code = presenter?.code(from: url) {
                delegate?.webViewViewController(self, didAuthenticateWithCode: code)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
    
    // MARK: - Извлечение кода авторизации из URL-адреса перенаправления
    private func code(from url: URL) -> String? {
        presenter?.code(from: url)
    }
}

