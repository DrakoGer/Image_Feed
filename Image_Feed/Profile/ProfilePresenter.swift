//
//  ProfilePresenter.swift
//  Image_Feed
//
//  Created by Yura on 22.03.25.
//

import Foundation
import UIKit

// Протоколы
protocol ProfileViewControllerProtocol: AnyObject {
    var presenter: ProfilePresenterProtocol? { get set }
    func updateProfileDetails(name: String, login: String, description: String?)
    func updateAvatar(url: URL?)
    func showLogoutAlert(completion: @escaping () -> Void)
}

protocol ProfilePresenterProtocol {
    var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
    func didTapLogoutButton()
    func logout()
}

// Протоколы для сервисов
protocol ProfileServiceProtocol {
    var profile: Profile? { get }
}

protocol ProfileImageServiceProtocol {
    static var didChangeNotification: Notification.Name { get }
    var avatarURL: String? { get }
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void)
}

protocol ProfileLogoutServiceProtocol {
    func logout()
}

extension ProfileService: ProfileServiceProtocol {}
extension ProfileImageService: ProfileImageServiceProtocol {}
extension ProfileLogoutService: ProfileLogoutServiceProtocol {}

// Презентер
final class ProfilePresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewControllerProtocol?
    private let profileService: ProfileServiceProtocol
    private let profileImageService: ProfileImageServiceProtocol
    private let logoutService: ProfileLogoutServiceProtocol
    private var profileImageObserver: NSObjectProtocol?
    
    init(
        profileService: ProfileServiceProtocol = ProfileService.shared,
        profileImageService: ProfileImageServiceProtocol = ProfileImageService.shared,
        logoutService: ProfileLogoutServiceProtocol = ProfileLogoutService.shared
    ) {
        self.profileService = profileService
        self.profileImageService = profileImageService
        self.logoutService = logoutService
    }
    
    func viewDidLoad() {
        print("🚀 [ProfilePresenter] viewDidLoad вызван")
        updateProfileDetails()
        loadAvatar()
        setupObservers()
    }
    
    private func updateProfileDetails() {
        guard let profile = profileService.profile else {
            print("⚠️ [ProfilePresenter] Профиль отсутствует в profileService")
            return
        }
        print("🔍 [ProfilePresenter] Обновление профиля: \(profile.name), \(profile.loginName), \(profile.bio ?? "нет bio")")
        view?.updateProfileDetails(
            name: profile.name,
            login: profile.loginName,
            description: profile.bio
        )
    }
    
    private func loadAvatar() {
        guard let username = profileService.profile?.username else {
            print("⚠️ [ProfilePresenter] Username отсутствует в профиле")
            view?.updateAvatar(url: nil)
            return
        }
        print("🔍 [ProfilePresenter] Загрузка аватарки для username: \(username)")
        profileImageService.fetchProfileImageURL(username: username) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let urlString):
                print("✅ [ProfilePresenter] Успешно получен URL аватарки: \(urlString)")
                if let url = URL(string: urlString) {
                    self.view?.updateAvatar(url: url)
                } else {
                    print("❌ [ProfilePresenter] Некорректный URL: \(urlString)")
                    self.view?.updateAvatar(url: nil)
                }
            case .failure(let error):
                print("❌ [ProfilePresenter] Ошибка загрузки аватарки: \(error.localizedDescription)")
                self.view?.updateAvatar(url: nil)
            }
        }
    }
    
    private func setupObservers() {
        print("🔧 [ProfilePresenter] Настройка наблюдателя за изменением аватарки")
        profileImageObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📡 [ProfilePresenter] Получено уведомление об изменении аватарки")
            self?.updateAvatar()
        }
    }
    
    private func updateAvatar() {
        guard let avatarURLString = profileImageService.avatarURL,
              let url = URL(string: avatarURLString) else {
            print("⚠️ [ProfilePresenter] avatarURL в ProfileImageService равен nil")
            view?.updateAvatar(url: nil)
            return
        }
        print("🔍 [ProfilePresenter] Обновление аватарки с URL: \(avatarURLString)")
        view?.updateAvatar(url: url)
    }
    
    func didTapLogoutButton() {
        view?.showLogoutAlert { [weak self] in
            self?.logout()
        }
    }
    
    func logout() {
        logoutService.logout()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = SplashViewController()
        }
    }
    
    deinit {
        if let observer = profileImageObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
