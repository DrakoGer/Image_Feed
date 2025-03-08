//
//  OAuthService.swift
//  Image_Feed
//
//  Created by Yura on 09.02.25.
//

import Foundation

final class OAuth2Service {
    // MARK: - Синглтон
    private var task: URLSessionTask?
    private var lastCode: String?
    static let shared = OAuth2Service()
    private let baseURL = "https://unsplash.com/oauth/token"
    private let storage = OAuth2TokenStorage()
    private let networkClient = NetworkClient()
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
        assert(Thread.isMainThread)
        
        if let currentTask = task {
            if lastCode == code {
                completion(.failure(.invalidRequest))
                return
            } else {
                currentTask.cancel()
            }
        }
        
        lastCode = code
        
        guard let request = makeOAuthTokenRequest(code: code) else {
            completion(.failure(.invalidRequest))
            print("❌ [OAuth2Service.fetchAuthToken] Ошибка: Неверный запрос на получение токена")
            return
        }
        
        print("📤 [OAuth2Service.fetchAuthToken] Отправка запроса: \(request)")
        
        let task = networkClient.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            DispatchQueue.main.async {
                self?.task = nil
                self?.lastCode = nil
                
                switch result {
                case .success(let responseBody):
                    print("✅ [OAuth2Service.fetchAuthToken] Токен успешно получен: \(responseBody.accessToken)")
                    self?.storage.token = responseBody.accessToken
                    completion(.success(responseBody.accessToken))
                case .failure(let error):
                    if let oauthError = error as? OAuthError {
                        print("❌ [OAuth2Service.fetchAuthToken] \(oauthError)")
                    } else {
                        print("❌ [OAuth2Service.fetchAuthToken] NetworkError: \(error.localizedDescription)")
                    }
                    completion(.failure(.networkError(error)))
                }
            }
        }
        self.task = task
        task.resume()
    }
}
