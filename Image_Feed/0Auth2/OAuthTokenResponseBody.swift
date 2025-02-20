//
//  OAuthTokenResponseBody.swift
//  Image_Feed
//
//  Created by Yura on 17.02.25.
//

import UIKit
import Foundation

// MARK: - Структура для декодинга JSON-ответа
struct OAuthTokenResponseBody: Decodable {
    let accessToken: String
    let tokenType: String
    let refreshToken: String?
    let scope: String
    let createdAt: Int
    let userId: Int
    let username: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
        case scope
        case createdAt = "created_at"
        case userId = "user_id"
        case username
    }
}
