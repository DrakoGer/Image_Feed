//
//  TabBarController.swift
//  Image_Feed
//
//  Created by Yura on 09.03.25.
//

import UIKit

final class TabBarController: UITabBarController {
    override func awakeFromNib() {
        super.awakeFromNib()
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        
        let imagesListViewController = storyboard.instantiateViewController(withIdentifier: "ImagesListViewController") as! ImagesListViewController
        let imageService = ImageServiceImpl()
        let presenter = ImagesListPresenterImpl(view: imagesListViewController, imageService: imageService)
        imagesListViewController.presenter = presenter
        
        let profileViewController = ProfileViewController()
        profileViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_profile_active"),
            selectedImage: nil
        )
        self.viewControllers = [imagesListViewController, profileViewController]
    }
}

