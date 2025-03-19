//
//  ProfileService.swift
//  Image_Feed
//
//  Created by Yura on 01.03.25.
//

import Foundation

// MARK: - Модель ответа API
struct ProfileResult: Decodable {
    let username: String
    let firstName: String?
    let lastName: String?
    let bio: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}

// MARK: - Модель профиля для UI
struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?
}

// MARK: - Сервис профиля
extension Profile {
    init(result profile: ProfileResult) {
        self.init(username: profile.username,
                  name: "\(profile.firstName ?? "") \(profile.lastName ?? "")".trimmingCharacters(in: .whitespaces),
                  loginName: "@\(profile.username)",
                  bio: profile.bio)
    }
}

final class ProfileService {
    
    static let shared = ProfileService()
    private let networkClient = NetworkClient()
    
    let storage = OAuth2TokenStorage()
    private var task: URLSessionTask?
    private let jsonDecoder = JSONDecoder()
    
    var profile: Profile?
    
    private init() {}
    
    static let didChangeNotification = Notification.Name("ProfileServiceDidChange")
    
    func updateProfile(_ profile: Profile) {
        self.profile = profile
        NotificationCenter.default.post(name: ProfileService.didChangeNotification, object: nil)
    }
    
    // MARK: - Создание запроса
    private func makeProfileURLRequest(token: String) -> URLRequest? {
        print("🟢 [ProfileService] makeProfileURLRequest() вызван")
        let baseURL = Constants.defaultBaseURL
        
        guard let url = URL(string: "/me", relativeTo: baseURL) else {
            print("❌ Ошибка: Невозможно создать URL запроса профиля")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    func clearProfile() {
        profile = nil
        NotificationCenter.default.post(name: ProfileService.didChangeNotification, object: self)
        print("Профиль удален")
    }
    
    // MARK: - Получение профиля
    func fetchProfile(completion: @escaping (Result<Profile, Error>) -> Void) {
        print("🟢 [ProfileService.fetchProfile] вызван")
        guard let token = storage.token else {
            print("❌ [ProfileService.fetchProfile] Ошибка: Токен отсутствует в хранилище!")
            completion(.failure(NSError(domain: "ProfileService", code: 401, userInfo: nil)))
            return
        }
        print("✅ [ProfileService.fetchProfile] Найден токен: \(token)")
        
        assert(Thread.isMainThread)
        
        guard let url = URL(string: "https://api.unsplash.com/me") else {
            completion(.failure(NSError(domain: "ProfileService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Неверный URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        print("🔍 [ProfileService.fetchProfile] Формируем запрос: URL=\(url.absoluteString), Authorization=\(request.value(forHTTPHeaderField: "Authorization") ?? "не задано")")
        
        networkClient.objectTask(for: request) { (result: Result<ProfileResult, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let profileResult):
                    let profile = Profile(result: profileResult)
                    self.profile = profile
                    completion(.success(profile))
                case .failure(let error):
                    print("❌ [ProfileService.fetchProfile] Ошибка получения профиля: \(error.localizedDescription) (код: \(error._code))")
                    if let nsError = error as NSError?, let data = nsError.userInfo["data"] as? Data,
                       let responseString = String(data: data, encoding: .utf8) {
                        print("🔍 [ProfileService.fetchProfile] Тело ответа: \(responseString)")
                    }
                    completion(.failure(error))
                }
            }
        }
    }
}
