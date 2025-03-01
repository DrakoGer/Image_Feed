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
    
    @IBOutlet weak var entryButton: UIButton!
    
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
            print("Переход на WebViewViewController")
            
            guard let webViewViewController = segue.destination as? WebViewViewController else {
                assertionFailure("Ошибка: не удалось привести segue.destination к WebViewViewController")
                return
            }
            
            webViewViewController.delegate = self
            
            if webViewViewController.delegate == nil {
                print("Delegate не установлен в prepare(for:sender:)!")
            } else {
                print("Delegate успешно установлен в prepare(for:sender:)")
            }
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
                    
                    if self.delegate == nil {
                        print("Delegate в AuthViewController равен nil перед вызовом didAuthenticate!")
                    } else {
                        print("Delegate вызван, переходим дальше")
                        self.delegate?.didAuthenticate(self)
                    }
                    
                    if self.delegate == nil {
                        print("Delegate в AuthViewController равен nil!")
                    } else {
                        print("Delegate вызван, переходим дальше")
                        self.delegate?.didAuthenticate(self)
                    }
                    
                case .failure(let error):
                    print("Ошибка авторизации: \(error.localizedDescription)")
                    self.showAuthErrorAlert()
                }
            }
        }
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        print("Отмена аутентификации пользователем")
        print("Закрываем WebView и передаём управление")
        vc.dismiss(animated: true)
        self.delegate?.didAuthenticate(self)
    }
    
    // MARK: - Метод показа ошибки при авторизации
    private func showAuthErrorAlert() {
        let alert = UIAlertController(
            title: "Ошибка авторизации",
            message: "Не удалось выполнить вход. Попробуйте ещё раз.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
