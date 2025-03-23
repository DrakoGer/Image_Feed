//
//  AuthViewController.swift
//  Image_Feed
//
//  Created by Yura on 04.02.25.
//

import UIKit
import ProgressHUD

final class AuthViewController: UIViewController {
    
    weak var delegate: AuthViewControllerDelegate?
    private let showWebViewSegueIdentifier = "showWebView"
    private let oauth2Service = OAuth2Service.shared
    
    @IBOutlet weak var entryButton: UIButton! {
        didSet {
                    entryButton.accessibilityIdentifier = "LoginButton" // Убедитесь, что это есть
                }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        entryButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Появился AuthViewController: \(self), Delegate: \(String(describing: delegate))")
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {
            guard let webViewViewController = segue.destination as? WebViewViewController else {
                assertionFailure("Ошибка: не удалось привести segue.destination к WebViewViewController")
                return
            }
            let authHelper = AuthHelper()
            let webWiewPresenter = WebViewPresenterImpl(authHelper: authHelper)
            webViewViewController.presenter = webWiewPresenter
            webWiewPresenter.view = webViewViewController
            webViewViewController.delegate = self
            
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

// MARK: - Реализация делегата WebViewViewControllerDelegate
extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        print("WebView завершает работу, код: \(code)")
        
        UIBlockingProgressHUD.show()
        
        oauth2Service.fetchAuthToken(code: code) { [weak self] result in
            guard let self = self else { return }
            
            UIBlockingProgressHUD.dismiss()
            
            DispatchQueue.main.async {
                switch result {
                case .success(let token):
                    print("Токен получен: \(token)")
                    
                    if let navController = self.navigationController {
                        print("Используем popViewController")
                        navController.popViewController(animated: true)
                    } else {
                        print("Используем dismiss")
                        vc.dismiss(animated: true)
                    }
                    
                    self.delegate?.didAuthenticate(self)
                    
                case .failure(let error):
                    print("❌ [AuthViewController] Ошибка авторизации: \(error.localizedDescription)")
                    vc.dismiss(animated: true) {
                        self.showAuthErrorAlert()
                    }
                }
            }
        }
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        print("Отмена аутентификации пользователем")
        vc.dismiss(animated: true)
        self.delegate?.didAuthenticate(self)
    }
    
    // MARK: - Метод показа ошибки при авторизации
    private func showAuthErrorAlert() {
        guard presentedViewController == nil else {
            print("⚠️ Другой контроллер уже открыт, не показываем алерт")
            return
        }
        let alert = UIAlertController(
            title: "Что-то пошло не так",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

