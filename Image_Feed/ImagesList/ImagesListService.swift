//
//  ImagesListService.swift
//  Image_Feed
//
//  Created by Yura on 12.03.25.
//

import Foundation

enum NetworkError: Error {
    case badURL
    case decodeError
}

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
        print("Фото и данные страниц удалены")
    }
    
    func fetchPhotosNextPage() {
        guard task == nil else {
            print("🔴 [ImagesListService] Запрос уже выполняется")
            return
        }
        
        let nextPage = (lastLoadedPage ?? 0) + 1
        guard var urlComponents = URLComponents(string: "https://api.unsplash.com/photos") else {
            print("🔴 [ImagesListService] Ошибка создания URL")
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
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                let dataString = String(data: data ?? Data(), encoding: .utf8) ?? "nil"
                return
            }
                        
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let photoResults = try decoder.decode([PhotoResult].self, from: data)
                let photos = photoResults.map(Photo.init)
                
                DispatchQueue.main.async {
                    self.photos.append(contentsOf: photos)
                    self.lastLoadedPage = nextPage
                    NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
                }
            } catch {
                print("🔴 \(error.localizedDescription)")
            }
        }
        self.task = task
        task.resume()
    }
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "https://api.unsplash.com/photos/\(photoId)/like") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        if let token = OAuth2TokenStorage().token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            self.task = nil
        
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                
            }
            
            guard let response = response as? HTTPURLResponse,
                  (200...299).contains(response.statusCode) else {
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

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let fullImageURL: String
    var isLiked: Bool
    
    mutating func toggleLike() {
        isLiked.toggle()
    }
}

extension Photo {
    init(photoResult: PhotoResult) {
        id = photoResult.id
        size = CGSize(width: Double(photoResult.width), height: Double(photoResult.height))
        createdAt = if let createdAt = photoResult.createdAt {
            ISO8601DateFormatter().date(from: createdAt)
        } else {
            nil
        }
        welcomeDescription = photoResult.description
        thumbImageURL = photoResult.urls.thumb
        largeImageURL = photoResult.urls.full
        fullImageURL = photoResult.urls.full
        isLiked = photoResult.likedByUser
    }
}
