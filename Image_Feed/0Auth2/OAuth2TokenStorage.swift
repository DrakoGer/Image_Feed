//
//  OAuth2TokenStorage.swift
//  Image_Feed
//
//  Created by Yura on 09.02.25.
//

import UIKit
import Foundation

// MARK: - Сохранение токена (Bearer Token) в User Defaults
final class OAuth2TokenStorage {
    
    var token: String? {
        get {
            return UserDefaults.standard.string(forKey: "AuthToken")
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "AuthToken")
        }
    }
}
