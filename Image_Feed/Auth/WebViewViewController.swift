//
//  WebViewViewController.swift
//  Image_Feed
//
//  Created by Yura on 06.02.25.
//

import UIKit
@preconcurrency import WebKit

enum WebViewConstants {
    static let unsplashAuthorizedURLString = "https://unsplash.com/oauth/authorize"
    
}

final class WebViewViewController: UIViewController {
    
    @IBOutlet  var webView: WKWebView!
    @IBOutlet  var progressView: UIProgressView!
    @IBOutlet weak var backButton: UIButton!
    
    weak var delegate: WebViewViewControllerDelegate?
    
    private var progressObservation: NSKeyValueObservation?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        loadAuthView()
        
        progressObservation = webView.observe(
            \.estimatedProgress,
             options: [.new],
             changeHandler: { [weak self] _, _ in
                 guard let self = self else { return }
                 self.updateProgress()
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
        guard var urlComponents = URLComponents(string: WebViewConstants.unsplashAuthorizedURLString) else {
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Constants.accessScope)
        ]
        
        guard let url = urlComponents.url else {
            return
        }
        
        print("Запрос на авторизацию по URL: \(url.absoluteString)")
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func updateProgress() {
        progressView.setProgress(Float(webView.estimatedProgress), animated: true)
        progressView.isHidden = fabs(webView.estimatedProgress - 1.0) <= 0.0001
    }
}

// MARK: - WKNavigationDelegate
extension WebViewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            print("Перенаправление на URL: \(url.absoluteString)")
            if let code = code(from: url) {
                print("Получен код авторизации: \(code)")
                
                if delegate == nil {
                    print("Delegate равен nil!")
                } else {
                    print("Delegate установлен")
                }
                
                delegate?.webViewViewController(self, didAuthenticateWithCode: code)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
    
    // MARK: - Извлечение кода авторизации из URL-адреса перенаправления
    private func code(from url: URL) -> String? {
        print("🔍 [WebViewViewController] Проверяем URL: \(url.absoluteString)")
        if let urlComponents = URLComponents(string: url.absoluteString),
           let queryItems = urlComponents.queryItems {
            for item in queryItems {
                print("🔍 [WebViewViewController] Query item: \(item.name)=\(item.value ?? "nil")")
            }
            return queryItems.first(where: { $0.name == "code" })?.value
        }
        print("Не найден код авторизации")
        return nil
    }
}

