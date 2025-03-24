//
//  ProfileImageService.swift
//  Image_Feed
//
//  Created by Yura on 02.03.25.
//

import UIKit

final class ProfileImageService {
    static let shared = ProfileImageService()
    private let profileService = ProfileService.shared
    
    internal(set) var avatarURL: String?
    
    static let didChangeNotification = Notification.Name("ProfileImageProviderDidChange")
    
    private init() {}
    
    func clearAvatar() {
        avatarURL = nil
        NotificationCenter.default.post(name: ProfileImageService.didChangeNotification, object: self)
        print("Аватарка удалена")
    }
    
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        guard let profile = profileService.profile else {
            completion(.failure(NSError(domain: "ProfileImageService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Profile not found"])))
            return
        }
        
        guard profile.username == username else {
            completion(.failure(NSError(domain: "ProfileImageService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Username mismatch"])))
            return
        }
        
        guard let avatarURL = profile.avatarURL else {
            completion(.failure(NSError(domain: "ProfileImageService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Avatar URL not found"])))
            return
        }
        
        self.avatarURL = avatarURL
        NotificationCenter.default.post(
            name: ProfileImageService.didChangeNotification,
            object: self,
            userInfo: ["URL": avatarURL]
        )
        completion(.success(avatarURL))
    }
}



