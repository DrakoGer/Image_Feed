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
        case codeError
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
}


