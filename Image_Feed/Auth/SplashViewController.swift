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
    private let showAuthenticationScreenSegueIdentifier = "showAuthenticationScreen"
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkAuth()
        
    }
    // MARK: - Проверка Аутентификации
    private func checkAuth() {
        guard let token = storage.token else {  // ✅ Теперь используем сохранённый токен
            performSegue(withIdentifier: showAuthenticationScreenSegueIdentifier, sender: nil)
            return
        }
        fetchProfile(token) // ✅ Передаём токен в метод
    }
    // MARK: - Навигация
    private func switchTabBarController() {
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Ошибка конфигурации")
            return
        }
        
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
        
        window.rootViewController = tabBarController
    }
}

// MARK: - Загрузка профиля
private extension SplashViewController {
    func fetchProfile(_ token: String) {
        print("🟢 [SplashViewController] fetchProfile() вызван с токеном: \(token)")
        UIBlockingProgressHUD.show()  // ✅ Блокируем UI, пока загружается профиль
        
        
        // Добавляем отладочный лог для сравнения токенов
        if let storedToken = profileService.storage.token {
            print("🔍 [SplashViewController] Токен из storage: \(storedToken)")
            print("🔍 [SplashViewController] Совпадают ли токены: \(token == storedToken)")
        } else {
            print("⚠️ [SplashViewController] Токен в storage отсутствует!")
        }
        
        profileService.fetchProfile() { [weak self] result in
            UIBlockingProgressHUD.dismiss()  // ✅ Разблокируем UI после завершения запроса
            
            guard let self = self else { return }
            
            switch result {
            case .success:
                print("✅ Профиль загружен успешно")
                self.switchTabBarController()  // ✅ После загрузки профиля переходим к TabBarController
            case .failure(let error):
                print("❌ Ошибка загрузки профиля: \(error)")
                // TODO: Добавить показ ошибки пользователю
            }
        }
    }
}

extension SplashViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("🔄 SplashViewController prepare(for segue:) вызван")
        if segue.identifier == showAuthenticationScreenSegueIdentifier {
            guard let navigationController = segue.destination as? UINavigationController,
                  let authViewController = navigationController.viewControllers.first as? AuthViewController else {
                assertionFailure("Ошибка: не удалось перейти на AuthViewController")
                return
            }
            
            authViewController.delegate = self
            print("Delegate установили  в SplashViewController: \(self)")
            print("Делегат AuthViewController: \(String(describing: authViewController.delegate))")
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

// MARK: - AuthViewControllerDelegate
extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        vc.dismiss(animated: true) { [weak self] in
            guard let self = self, let token = self.storage.token else { return }
            self.fetchProfile(token)  // ✅ После авторизации загружаем профиль, затем переходим к TabBar
            
            // Теперь загружаем аватарку
            if let username = self.profileService.profile?.username {
                ProfileImageService.shared.fetchProfileImageURL(username: username) { _ in }
            }
        }
    }
}

