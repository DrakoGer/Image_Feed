//
//  OAuth2TokenStorage.swift
//  Image_Feed
//
//  Created by Yura on 09.02.25.
//

import UIKit
import Foundation
import SwiftKeychainWrapper

// MARK: - Сохранение токена (Bearer Token) в Keychain
final class OAuth2TokenStorage {
    private let tokenKey = "AuthToken"
    
    var token: String? {
        get {
            print("🔍 [OAuth2TokenStorage] Получение токена из Keychain")
            let token = KeychainWrapper.standard.string(forKey: tokenKey)
            print("🔍 [OAuth2TokenStorage] Токен: \(token ?? "nil")")
            return token
        }
        set {
            if let newValue = newValue {
                print("🔄 [OAuth2TokenStorage] Сохранение токена в Keychain: \(newValue)")
                let success = KeychainWrapper.standard.set(newValue, forKey: tokenKey)
                if !success {
                    print("❌ [OAuth2TokenStorage] Ошибка сохранения токена в Keychain")
                }
            } else {
                print("🗑️ [OAuth2TokenStorage] Удаление токена из Keychain")
                let success = KeychainWrapper.standard.removeObject(forKey: tokenKey)
                if !success {
                    print("❌ [OAuth2TokenStorage] Ошибка удаления токена из Keychain")
                }
            }
        }
    }
}
