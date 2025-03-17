//
//  ProfileImageService.swift
//  Image_Feed
//
//  Created by Yura on 02.03.25.
//

import UIKit
import Kingfisher

final class ProfileImageService {
    
    static let shared = ProfileImageService()
    private let networkClient = NetworkClient()
    private let storage = OAuth2TokenStorage()
    private let imageCache = ImageCache.default
    
    private(set) var avatarURL: String?
    private(set) var avatarImage: UIImage?
    
    static let didChangeNotification = Notification.Name("ProfileImageProviderDidChange")
    
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }
    
    private init() {}
    
    func clearAvatar() {
        avatarURL = nil
        NotificationCenter.default.post(name: ProfileImageService.didChangeNotification, object: self)
        print("Аватарка удалена")
    }
    
    func fetchProfileImageURL(username: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        assert(Thread.isMainThread)
        print("🟢 [ProfileImageService.fetchProfileImageURL] вызван с username: \(username)")
        print("Token: \(storage.token ?? "nil")")
        
        guard !username.isEmpty else {
            print("❌ [ProfileImageService.fetchProfileImageURL] Ошибка: username пустой")
            completion(.failure(NSError(domain: "ProfileImageService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Username is empty"])))
            return
        }
        
        guard let token = storage.token else {
            print("❌ [ProfileImageService.fetchProfileImageURL] Ошибка: Токен отсутствует в хранилище!")
            completion(.failure(NSError(domain: "AuthError", code: 401, userInfo: nil)))
            return
        }
        print("✅ [ProfileImageService.fetchProfileImageURL] Токен найден: \(token)")
        
        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
            print("❌ [ProfileImageService.fetchProfileImageURL] Ошибка: Неверный URL для username: \(username)")
            completion(.failure(NSError(domain: "URLError", code: 400, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let task = networkClient.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let userResult):
                    let profileImageURL = userResult.profileImage.small
                    self.avatarURL = profileImageURL
                    print("🔍 [ProfileImageService.fetchProfileImageURL] Получен URL аватарки: \(profileImageURL)")
                    
                    guard let imageURL = URL(string: profileImageURL) else {
                        print("❌ [ProfileImageService.fetchProfileImageURL] Ошибка: Неверный URL изображения: \(profileImageURL)")
                        completion(.failure(NSError(domain: "URLError", code: 400, userInfo: nil)))
                        return
                    }
                    self.imageCache.clearMemoryCache()
                    KingfisherManager.shared.retrieveImage(with: imageURL, options: nil) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let value):
                            self.avatarImage = value.image
                            print("✅ [ProfileImageService.fetchProfileImageURL] Аватарка загружена: \(profileImageURL)")
                            NotificationCenter.default.post(
                                name: ProfileImageService.didChangeNotification,
                                object: self,
                                userInfo: ["URL": profileImageURL, "image": value.image]
                            )
                            completion(.success(value.image))
                        case .failure(let error):
                            print("❌ [ProfileImageService.fetchProfileImageURL] Ошибка загрузки изображения: \(error.localizedDescription)")
                            completion(.failure(error))
                        }
                    }
                    
                case .failure(let error):
                    print("❌ [ProfileImageService.fetchProfileImageURL] Ошибка получения данных профиля: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
            
            print("🔍 [ProfileImageService.fetchProfileImageURL] Отправлен запрос: URL=\(url.absoluteString), HTTPMethod=\(request.httpMethod ?? "GET")")
            if let authorization = request.value(forHTTPHeaderField: "Authorization") {
                print("🔍 [ProfileImageService.fetchProfileImageURL] Заголовок Authorization: \(authorization)")
            } else {
                print("⚠️ [ProfileImageService.fetchProfileImageURL] Заголовок Authorization отсутствует!")
            }
        }
        task.resume()
    }
}

// MARK: - Модель для декодирования JSON
struct UserResult: Codable {
    let profileImage: ProfileImage
    
    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

struct ProfileImage: Codable {
    let small: String
}



