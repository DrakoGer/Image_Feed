//
//  OAuthService.swift
//  Image_Feed
//
//  Created by Yura on 09.02.25.
//

import Foundation

import Foundation

final class OAuth2Service {
    
    // MARK: - Синглтон
    static let shared = OAuth2Service()
    private let baseURL = "https://unsplash.com/oauth/token"
    private let storage = OAuth2TokenStorage()
    private init() {}
    
        // MARK: - Запрос Токена
    func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let baseURL = URL(string: "https://unsplash.com") else {
            fatalError("Invalid base URL")
        }
        
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.path = "/oauth/token"
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectUri),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        
        guard let url = components.url else {
            fatalError("Failed to construct URL from components")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
    
    enum OAuthError: Error {
        case invalidRequest
        case networkError(Error)
        case invalidHTTPResponse
        case invalidStatusCode(Int)
        case invalidData
        case decodingFailed(Error)
        
    }
    
        // MARK: - Извлечение токена
    func fetchAuthToken(code: String, completion: @escaping (Result<String, OAuthError>) -> Void) {
        guard let request = makeOAuthTokenRequest(code: code) else {
            completion(.failure(.invalidRequest))
            print("❌ Ошибка: Неверный запрос на получение токена")
            return
        }
        
        print("📤 Отправка запроса: \(request)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                    print("❌ Ошибка сети:", error.localizedDescription)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidHTTPResponse))
                    print("❌ Ошибка: Некорректный HTTP-ответ")
                }
                return
            }
            
            print("📥 Код ответа от сервера:", httpResponse.statusCode)
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidStatusCode(httpResponse.statusCode)))
                    print("❌ Ошибка: Недопустимый статус-код \(httpResponse.statusCode)")
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidData))
                    print("❌ Ошибка: Данные от сервера отсутствуют")
                }
                return
            }
            
            print("📥 Ответ от сервера:", String(data: data, encoding: .utf8) ?? "Нет данных")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("jsonString: \(jsonString)")
            } else {
                print("Error: invalid JSON")
            }
            do {
                let decoder = JSONDecoder()
                print("Полученные данные JSON:", String(data: data, encoding: .utf8) ?? "Нет данных")
                print("📥 JSON перед декодированием:", String(data: data, encoding: .utf8) ?? "Нет данных")
                
                let responseBody = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                
                print("✅ Токен успешно получен:", responseBody.accessToken)
                self.storage.token = responseBody.accessToken
                
                DispatchQueue.main.async {
                    completion(.success(responseBody.accessToken))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.decodingFailed(error)))
                    print("❌ Ошибка декодирования JSON:", error.localizedDescription)
                }
            }
        }
        task.resume()
    }
}
