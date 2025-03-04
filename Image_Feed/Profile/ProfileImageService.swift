//
//  ProfileImageService.swift
//  Image_Feed
//
//  Created by Yura on 02.03.25.
//

import Foundation

final class ProfileImageService {
    
    static let shared = ProfileImageService() // Синглтон
    private let networkClient = NetworkClient()
    private let storage = OAuth2TokenStorage()
    
    private(set) var avatarURL: String?
    
    // Уведомление о смене аватарки
    static let didChangeNotification = Notification.Name("ProfileImageProviderDidChange")
    
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        print("🟢 [ProfileImageService] fetchProfileImageURL() вызван")

        guard let token = storage.token else {
            completion(.failure(NSError(domain: "AuthError", code: 401, userInfo: nil)))
            return
        }
        print("✅ [ProfileImageService] Токен найден: \(token)")

        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
            print("❌ [ProfileImageService] Ошибка: Неверный URL")
            completion(.failure(NSError(domain: "URLError", code: 400, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let task = networkClient.objectTask(for: request) { (result: Result<UserResult, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let userResult):
                    let profileImageURL = userResult.profileImage.small
                    self.avatarURL = profileImageURL
                    print("🔍 [ProfileImageService] Ответ сервера: Успешно, URL аватарки: \(profileImageURL)")
                    print("✅ [ProfileImageService] Аватарка загружена: \(profileImageURL)")

                    NotificationCenter.default.post(
                        name: ProfileImageService.didChangeNotification,
                        object: self,
                        userInfo: ["URL": profileImageURL]
                    )

                    completion(.success(profileImageURL))

                case .failure(let error):
                    print("❌ [ProfileImageService] Ошибка загрузки аватарки: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }

            // Логируем детали запроса до отправки
            print("🔍 [ProfileImageService] Отправлен запрос: URL=\(url.absoluteString), HTTPMethod=\(request.httpMethod ?? "GET")")
            if let authorization = request.value(forHTTPHeaderField: "Authorization") {
                print("🔍 [ProfileImageService] Заголовок Authorization: \(authorization)")
            } else {
                print("⚠️ [ProfileImageService] Заголовок Authorization отсутствует!")
            }
        }
        task.resume() // 👈 БЕЗ ЭТОГО ЗАПРОС НЕ ВЫПОЛНЯЕТСЯ!
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

