//
//  SplashViewController.swift
//  Image_Feed
//
//  Created by Yura on 17.02.25.
//

import UIKit

final class SplashViewController: UIViewController {
    private let profileService = ProfileService.shared
    private let storage = OAuth2TokenStorage()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "splash_screen_logo")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkAuth()
    }
    
    private func setupUI() {
        view.backgroundColor = #colorLiteral(red: 0.1019607843, green: 0.1058823529, blue: 0.1333333333, alpha: 1)
        view.addSubview(logoImageView)
        
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Проверка Аутентификации
    private func checkAuth() {
        print("🟢 [SplashViewController] Проверка авторизации")
        guard let token = storage.token else {
            showAuthViewController()
            return
        }
        fetchProfile(token)
    }
    
    // MARK: - Навигация
    private func switchTabBarController() {
        print("🔄 [SplashViewController] Переход к TabBarController")
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Ошибка конфигурации")
            return
        }
        
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
        
        window.rootViewController = tabBarController
    }
    
    private func showAuthViewController() {
        print("🔄 [SplashViewController] Переход к AuthViewController")
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let authViewController = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else {
            assertionFailure("Ошибка: не удалось создать AuthViewController")
            return
        }
        
        authViewController.delegate = self
        authViewController.modalPresentationStyle = .fullScreen
        present(authViewController, animated: true)
    }
    
    // MARK: - Загрузка профиля
    private func fetchProfile(_ token: String) {
        print("🟢 [SplashViewController] fetchProfile() вызван с токеном: \(token)")
        UIBlockingProgressHUD.show()
        
        if let storedToken = storage.token {
            print("🔍 [SplashViewController] Токен из storage: \(storedToken)")
        } else {
            print("⚠️ [SplashViewController] Токен в storage отсутствует!")
        }
        
        profileService.fetchProfile { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            
            guard let self = self else { return }
            
            switch result {
            case .success:
                print("✅ Профиль загружен успешно")
                if let username = self.profileService.profile?.username {
                    ProfileImageService.shared.fetchProfileImageURL(username: username) { result in
                        switch result {
                        case .success(let image):
                            print("✅ [SplashViewController] Аватарка загружена: \(image)")
                        case .failure(let error):
                            print("❌ [SplashViewController] Ошибка загрузки аватарки: \(error)")
                        }
                    }
                }
                self.switchTabBarController()
            case .failure(let error):
                print("❌ Ошибка загрузки профиля: \(error)")
            }
        }
    }
}

// MARK: - AuthViewControllerDelegate
extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        vc.dismiss(animated: true) { [weak self] in
            guard let self = self, let token = self.storage.token else { return }
            self.fetchProfile(token)
        }
    }
}


