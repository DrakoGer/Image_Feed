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
    
    private let urlSession = URLSession.shared
    private let storage = OAuth2TokenStorage() // ✅ Теперь используем один экземпляр
    private var task: URLSessionTask?
    private let jsonDecoder = JSONDecoder()
    
    var profile: Profile?
    
    private init() {}
    
    // MARK: - Создание запроса
    private func makeProfileURLRequest(token: String) -> URLRequest? {
        let baseURL = Constants.defaultBaseURL  // Используем напрямую, без guard let
        
        guard let url = URL(string: "/me", relativeTo: baseURL) else {
            print("❌ Ошибка: Невозможно создать URL запроса профиля")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    // MARK: - Получение профиля
    func fetchProfile(completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        task?.cancel()  // ✅ Отменяем старый запрос
        task = nil       // ✅ Обнуляем задачу, чтобы не хранить ссылку на отменённую
        
        guard let token = storage.token else {
            completion(.failure(NSError(domain: "ProfileService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Токен отсутствует"])))
            return
        }
        
        guard let request = makeProfileURLRequest(token: token) else {
            completion(.failure(NSError(domain: "ProfileService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Неверный запрос"])))
            return
        }
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.task = nil  // ✅ После выполнения запроса обнуляем задачу
                
                if let error = error {
                    print("❌ Ошибка сети: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    print("❌ Ошибка HTTP: Код \(statusCode)")
                    completion(.failure(NSError(domain: "ProfileService", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Ошибка HTTP"])))
                    return
                }
                
                guard let data = data else {
                    print("❌ Ошибка: Данные отсутствуют")
                    completion(.failure(NSError(domain: "ProfileService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Данные отсутствуют"])))
                    return
                }
                
                do {
                    let profileResult = try self.jsonDecoder.decode(ProfileResult.self, from: data)
                    let profile = Profile(result: profileResult)
                    self.profile = profile  // ✅ Сохраняем профиль
                    completion(.success(profile))
                } catch {
                    print("❌ Ошибка декодирования JSON: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
        
        self.task = task  // ✅ Сохраняем ссылку на активный запрос
        task.resume()
    }
}
