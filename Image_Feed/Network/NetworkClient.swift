//
//  NetworkClient.swift
//  Image_Feed
//
//  Created by Yura on 17.02.25.
//

import UIKit
import Foundation

struct NetworkClient: NetworkRouting {
    
    private enum NetworkError: Error {
        case codeError(Int)
        case noData
        case decodingError(Error)
    }
    
    func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void) {
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                handler(.failure(error))
                return
            }
            
            if let response = response as? HTTPURLResponse,
               response.statusCode < 200 || response.statusCode >= 300 {
                handler(.failure(NSError(domain: "", code: response.statusCode, userInfo: nil)))
                return
            }
            
            guard let data = data else {
                handler(.failure(NSError(domain: "", code: -1, userInfo: nil)))
                return
            }
            handler(.success(data))
        }
        task.resume()
    }
    
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [NetworkClient] Ошибка запроса: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let response = response as? HTTPURLResponse,
               response.statusCode < 200 || response.statusCode >= 300 {
                print("❌ [NetworkClient] Ошибка HTTP: \(response.statusCode)")
                let userInfo = data != nil ? [ "data": data! ] : nil
                completion(.failure(NSError(domain: "", code: response.statusCode, userInfo: userInfo)))
                return
            }
            
            guard let data = data else {
                print("❌ [NetworkClient] Ошибка: Данные отсутствуют")
                completion(.failure(NSError(domain: "", code: -1, userInfo: nil)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let decodedObject = try decoder.decode(T.self, from: data)
                print("✅ [NetworkClient] JSON успешно декодирован: \(T.self)")
                completion(.success(decodedObject))
            } catch {
                print("❌ [NetworkClient] Ошибка декодирования: \(error.localizedDescription), Данные: \(String(data: data, encoding: .utf8) ?? "nil")")
                completion(.failure(error))
            }
        }
        
        task.resume()
        return task
    }
}
