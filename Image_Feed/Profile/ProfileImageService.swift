//
//  ProfileImageService.swift
//  Image_Feed
//
//  Created by Yura on 02.03.25.
//

import Foundation

final class ProfileImageService {
    
    static let shared = ProfileImageService() // Синглтон
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private let storage = OAuth2TokenStorage()
    
    private(set) var avatarURL: String?
    
    // Уведомление о смене аватарки
    static let didChangeNotification = Notification.Name("ProfileImageProviderDidChange")
    
    private init() {}

    /// Запрос URL аватарки по username
    func fetchProfileImageURL(username: String, _ completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        task?.cancel() // Отменяем предыдущий запрос, если был
        
        guard let token = storage.token else {
            completion(.failure(NSError(domain: "AuthError", code: 401, userInfo: nil)))
            return
        }
        
        let urlString = "https://api.unsplash.com/users/\(username)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "URLError", code: 400, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.task = nil
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data,
                      let userResult = try? JSONDecoder().decode(UserResult.self, from: data) else {
                    completion(.failure(NSError(domain: "DecodeError", code: 500, userInfo: nil)))
                    return
                }
                
                let profileImageURL = userResult.profileImage.small
                self.avatarURL = profileImageURL
                
                // Отправляем нотификацию
                NotificationCenter.default.post(
                    name: ProfileImageService.didChangeNotification,
                    object: self,
                    userInfo: ["URL": profileImageURL]
                )
                
                completion(.success(profileImageURL))
            }
        }
        self.task = task
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
