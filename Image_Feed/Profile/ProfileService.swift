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
    let profileImage: ProfileImage? // Изменяем на объект
    
    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
        case profileImage = "profile_image"
    }
}

struct ProfileImage: Decodable {
    let small: String?
    let medium: String?
    let large: String?
}

// MARK: - Модель профиля для UI
struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?
    let avatarURL: String?
}

// MARK: - Сервис профиля
extension Profile {
    init(result profile: ProfileResult) {
        self.init(
            username: profile.username,
            name: "\(profile.firstName ?? "") \(profile.lastName ?? "")".trimmingCharacters(in: .whitespaces),
            loginName: "@\(profile.username)",
            bio: profile.bio,
            avatarURL: profile.profileImage?.medium // Используем medium размер
        )
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
    
    private func makeProfileURLRequest(token: String) -> URLRequest? {
        let baseURL = Constants.defaultBaseURL
        
        guard let url = URL(string: "/me", relativeTo: baseURL) else {
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
    
    func fetchProfile(completion: @escaping (Result<Profile, Error>) -> Void) {
        guard let token = storage.token else {
            completion(.failure(NSError(domain: "ProfileService", code: 401, userInfo: nil)))
            return
        }
        
        assert(Thread.isMainThread)
        
        guard let url = URL(string: "https://api.unsplash.com/me") else {
            completion(.failure(NSError(domain: "ProfileService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Неверный URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        task = networkClient.objectTask(for: request) { (result: Result<ProfileResult, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let profileResult):
                    let profile = Profile(result: profileResult)
                    self.profile = profile
                    completion(.success(profile))
                case .failure(let error):
                    if let nsError = error as NSError?, let data = nsError.userInfo["data"] as? Data,
                       let responseString = String(data: data, encoding: .utf8) {
                    }
                    completion(.failure(error))
                }
            }
        }
        task?.resume()
    }
}
