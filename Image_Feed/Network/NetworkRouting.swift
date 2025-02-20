//
//  NetworkRouting.swift
//  Image_Feed
//
//  Created by Yura on 17.02.25.
//

import UIKit

protocol NetworkRouting {
    func fetch( url: URL, handler: @escaping (Result<Data, Error>) -> Void)
}
