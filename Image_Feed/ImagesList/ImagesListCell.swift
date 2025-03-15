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
    
    private weak var delegate: UITableViewDelegate? // Для перезагрузки ячейки
    
    // MARK: - Lifecycle
    override func prepareForReuse() {
        super.prepareForReuse()
        cellImage.kf.cancelDownloadTask() // Отмена загрузки при переиспользовании
    }
    
    // MARK: - Configuration
    func configure(with photo: Photo, delegate: UITableViewDelegate? = nil) {
        self.delegate = delegate
        
        // Загрузка изображения с заглушкой и индикатором
        let placeholder = UIImage(named: "placeholder") // Убедись, что заглушка есть в ассетах
        cellImage.kf.indicatorType = .activity
        if let url = URL(string: photo.thumbImageURL) {
            cellImage.kf.setImage(
                with: url,
                placeholder: placeholder,
                options: [.transition(.fade(0.2))],
                completionHandler: { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let value):
                        print("🔵 [ImagesListCell] Изображение загружено для ID: \(photo.id)")
                        // Перезагрузка ячейки для обновления высоты
                        if let tableView = self.superview as? UITableView,
                           let indexPath = tableView.indexPath(for: self) {
                            self.delegate?.tableView?(tableView, willDisplay: self, forRowAt: indexPath)
                            tableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                    case .failure(let error):
                        print("🔴 [ImagesListCell] Ошибка загрузки изображения: \(error.localizedDescription)")
                    }
                }
            )
        }
        
        // Настройка даты и лайка
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        dateLabel.text = formatter.string(from: photo.createdAt ?? Date())
        
        let likeImage = photo.isLiked ? UIImage(named: "likeActive") : UIImage(named: "likeNotActive")
        likeButton.setImage(likeImage, for: .normal)
    }
}
