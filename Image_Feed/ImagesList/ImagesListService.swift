//
//  ImagesListService.swift
//  Image_Feed
//
//  Created by Yura on 12.03.25.
//

import Foundation

final class ImagesListService {
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")
    
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    private let photosPerPage = 10
    private var task: URLSessionDataTask?
    private let urlSession = URLSession.shared
    
    private init() {}
    
    func clearPhotos() {
        photos.removeAll()
        lastLoadedPage = 0
        NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: self)
    }
    
    func fetchPhotosNextPage() {
        guard task == nil else {
            return
        }
        
        let nextPage = (lastLoadedPage ?? 0) + 1
        guard var urlComponents = URLComponents(string: "https://api.unsplash.com/photos") else {
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "\(nextPage)"),
            URLQueryItem(name: "per_page", value: "10")
        ]
        
        guard let url = urlComponents.url else {
            return
        }
        
        var request = URLRequest(url: url)
        if let token = OAuth2TokenStorage().token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            self.task = nil
            
            if let error = error {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.fetchPhotosNextPage()
                }
                return
            }
            
            guard let data = data,
                  let response = response as? HTTPURLResponse,
                  (200...299).contains(response.statusCode) else {
                _ = (response as? HTTPURLResponse)?.statusCode ?? 0
                _ = String(data: data ?? Data(), encoding: .utf8) ?? "nil"
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let photoResults = try decoder.decode([PhotoResult].self, from: data)
                let photos = photoResults.map { Photo(photoResult: $0) } // Без try, так как деградация
                
                DispatchQueue.main.async {
                    self.photos.append(contentsOf: photos)
                    self.lastLoadedPage = nextPage
                    NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
                }
            } catch {
                print("🔴 [ImagesListService] Ошибка декодирования: \(error.localizedDescription)")
            }
        }
        self.task = task
        task.resume()
    }
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "https://api.unsplash.com/photos/\(photoId)/like") else {
            completion(.failure(NSError(domain: "ImagesListService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        if let token = OAuth2TokenStorage().token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            completion(.failure(NSError(domain: "ImagesListService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Token not found"])))
            return
        }
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            self.task = nil
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
            
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "ImagesListService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                }
                return
            }
            DispatchQueue.main.async {
                completion(.success(()))
            }
        }
        
        self.task = task
        task.resume()
    }
}

struct PhotoResult: Decodable {
    let id: String
    let createdAt: String?
    let width: Int
    let height: Int
    let description: String?
    let likedByUser: Bool
    let urls: URLs
}

struct URLs: Decodable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

struct Photo: Equatable {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let fullImageURL: String
    var isLiked: Bool
    
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
    
    mutating func toggleLike() {
        isLiked.toggle()
    }
}

extension Photo {
    init(photoResult: PhotoResult) {
        id = photoResult.id
        size = CGSize(width: Double(photoResult.width), height: Double(photoResult.height))
        createdAt = photoResult.createdAt.flatMap { Self.isoFormatter.date(from: $0) }
        welcomeDescription = photoResult.description
        thumbImageURL = photoResult.urls.thumb
        largeImageURL = photoResult.urls.full
        fullImageURL = photoResult.urls.full
        isLiked = photoResult.likedByUser
    }
}
