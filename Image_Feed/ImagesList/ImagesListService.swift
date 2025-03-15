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
            print("🔴 [ImagesListService] Неверный URL")
            return
        }
        
        var request = URLRequest(url: url)
        if let token = OAuth2TokenStorage().token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔵 [ImagesListService] Токен: \(token)")
        } else {
            print("🔴 [ImagesListService] Токен не найден")
            return
        }
        
        print("🔵 [ImagesListService] Запрос: \(url.absoluteString)")
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            self.task = nil
            
            if let error = error {
                print("🔴 [ImagesListService] Ошибка сети: \(error.localizedDescription)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.fetchPhotosNextPage()
                }
                return
            }
            
            guard let data = data, let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                let dataString = String(data: data ?? Data(), encoding: .utf8) ?? "nil"
                print("🔴 [ImagesListService] Неверный ответ сервера, статус: \(statusCode), данные: \(dataString)")
                return
            }
            
            // Добавьте отладочный вывод перед декодированием
                if let dataString = String(data: data, encoding: .utf8) {
                    print("🔵 [ImagesListService] Полный JSON-ответ перед декодированием: \(dataString)")
                } else {
                    print("🔴 [ImagesListService] Не удалось преобразовать данные в строку")
                }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                // Убираем .iso8601, так как теперь парсим как String
                
                if let dataString = String(data: data, encoding: .utf8) {
                    print("🔵 [ImagesListService] Данные перед декодированием: \(dataString)")
                }
                
                let photoResults = try decoder.decode([PhotoResult].self, from: data)
                print("🔵 [ImagesListService] Успешно декодировано \(photoResults.count) объектов")
                
                // Создаём форматтер для преобразования String в Date
                let dateFormatter = ISO8601DateFormatter()
                
                var newPhotos: [Photo] = []
                let existingIDs = Set(self.photos.map { $0.id })
                
                for photoResult in photoResults {
                    guard let urls = photoResult.urls,
                          let thumb = urls.thumb,
                          let full = urls.full,
                          let width = photoResult.width,
                          let height = photoResult.height else {
                        print("🔴 [ImagesListService] Пропущена фотография с ID \(photoResult.id): отсутствуют обязательные поля")
                        continue
                    }
                    
                    if existingIDs.contains(photoResult.id) {
                        print("🔴 [ImagesListService] Пропущен дубликат с ID: \(photoResult.id)")
                        continue
                    }
                    
                    // Преобразуем createdAt из String в Date
                    let createdAt: Date?
                    if let createdAtString = photoResult.createdAt {
                        createdAt = dateFormatter.date(from: createdAtString)
                    } else {
                        createdAt = nil
                    }
                    
                    let photo = Photo(
                        id: photoResult.id,
                        size: CGSize(width: Double(width), height: Double(height)),
                        createdAt: createdAt,
                        welcomeDescription: photoResult.description,
                        thumbImageURL: thumb,
                        largeImageURL: full,
                        fullImageURL: full,
                        isLiked: photoResult.likedByUser ?? false
                    )
                    newPhotos.append(photo)
                }
                
                DispatchQueue.main.async {
                    self.photos.append(contentsOf: newPhotos)
                    self.lastLoadedPage = nextPage
                    NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
                    print("🔵 [ImagesListService] Загружено \(newPhotos.count) фото, всего: \(self.photos.count)")
                }
            } catch {
                if let dataString = String(data: data, encoding: .utf8) {
                    print("🔴 [ImagesListService] Данные от сервера при ошибке: \(dataString)")
                }
                print("🔴 [ImagesListService] Ошибка декодирования: \(error.localizedDescription)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .dataCorrupted(let context):
                        print("🔴 Data corrupted: \(context.debugDescription)")
                    case .keyNotFound(let key, let context):
                        print("🔴 Key '\(key)' not found: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("🔴 Type mismatch for \(type): \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("🔴 Value not found for \(type): \(context.debugDescription)")
                    @unknown default:
                        print("🔴 Unknown decoding error")
                    }
                }
            }
        }
        
        self.task = task
        task.resume()
    }
}

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let fullImageURL: String
    let isLiked: Bool
}

struct PhotoResult: Decodable {
    let id: String
    let createdAt: String? // Изменяем тип на String?
    let width: Int?
    let height: Int?
    let description: String?
    let likedByUser: Bool?
    let urls: UrlsResult?
    let likes: Int?
    let user: UserResult?
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case width
        case height
        case description
        case likedByUser = "liked_by_user"
        case urls
        case likes
        case user
    }
}

struct UrlsResult: Decodable {
    let raw: String?
    let full: String?
    let regular: String?
    let small: String?
    let thumb: String?
    let smallS3: String?
    
    enum CodingKeys: String, CodingKey {
        case raw
        case full
        case regular
        case small
        case thumb
        case smallS3 = "small_s3"
    }
}


