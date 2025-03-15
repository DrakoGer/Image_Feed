//
//  Photo.swift
//  Image_Feed
//
//  Created by Yura on 13.03.25.
//


import Foundation

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
