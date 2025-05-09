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
    @IBOutlet weak var likeButton: UIButton! {
        didSet {
            likeButton.accessibilityIdentifier = "like_button_on" // Убедитесь, что это есть
                }
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var onLikeTapped: (() -> Void)?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cellImage.kf.cancelDownloadTask()
        cellImage.image = nil
        dateLabel.text = nil
    }
    
    func configure(with photo: Photo) {
        let placeHolder = UIImage(named: "placeHolderForImageCell")
        cellImage.kf.indicatorType = .activity
        if let url = URL(string: photo.thumbImageURL) {
            cellImage.kf.setImage(with: url, placeholder: placeHolder)
        } else {
            cellImage.image = placeHolder
        }
        
        if let createdAt = photo.createdAt {
            dateLabel.text = Self.dateFormatter.string(from: createdAt)
        } else {
            dateLabel.text = ""
        }
        
        let likeImage = photo.isLiked ? UIImage(named: "likeActive") : UIImage(named: "likeNotActive")
        likeButton.setImage(likeImage, for: .normal)
    }
    
    @IBAction private func likeButtonDidTapped(_ sender: Any) {
        onLikeTapped?()
    }
}
