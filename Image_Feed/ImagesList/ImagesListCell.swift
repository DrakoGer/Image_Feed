//
//  ImagesListCell.swift
//  ImageFeed
//
//  Created by Yura on 28.12.24.
//

import UIKit
import Kingfisher

final class ImagesListCell: UITableViewCell {
    
    static let reuseIdentifier = "ImagesListCell"
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    
    //private var currentImageURL: String?
    
    var onLikeTapped: (() -> Void)?
    
    // MARK: - Lifecycle
    override func prepareForReuse() {
        super.prepareForReuse()
        cellImage.kf.cancelDownloadTask()
    }
    
    // MARK: - Configuration
    func configure(with photo: Photo) {
        let placeHolder = UIImage(named: "placeHolderForImageCell")
        cellImage.kf.indicatorType = .activity
        cellImage.kf.setImage(with: URL(string: photo.thumbImageURL), placeholder: placeHolder)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        dateLabel.text = formatter.string(from: photo.createdAt ?? Date())
        
        let likeImage = photo.isLiked ? UIImage(named: "likeActive") : UIImage(named: "likeNotActive")
        likeButton.setImage(likeImage, for: .normal)
    }
    
    @IBAction func likeButtonDidTapped(_ sender: Any) {
        onLikeTapped?()
    }
    

}
