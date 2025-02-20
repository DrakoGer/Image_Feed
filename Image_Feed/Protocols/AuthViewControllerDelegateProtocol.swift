//
//  AuthViewControllerDelegate.swift
//  Image_Feed
//
//  Created by Yura on 17.02.25.
//

import UIKit

protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}
