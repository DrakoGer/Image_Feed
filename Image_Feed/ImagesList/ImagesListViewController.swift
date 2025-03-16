//
//  ViewController.swift
//  ImageFeed
//
//  Created by Yura on 23.12.24.
//

import UIKit
import Kingfisher

final class ImagesListViewController: UIViewController {
    
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    var presenter: ImagesListPresenter?
    
    // MARK: - Outlets
    @IBOutlet private weak var tableView: UITableView!
    
    // MARK: - Properties
    private var photos: [Photo] = [] // Локальный массив фотографий
    private let imagesListService = ImagesListService.shared

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        // Подписка на обновления
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTableViewAnimated),
            name: ImagesListService.didChangeNotification,
            object: nil
        )
        
        imagesListService.fetchPhotosNextPage()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard let viewController = segue.destination as? SingleImageViewController,
                  let indexPath = sender as? IndexPath else {
                assertionFailure("Invalid segue destination")
                return
            }
            let photo = photos[indexPath.row]
            viewController.imageURL = URL(string: photo.largeImageURL)
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath) as? ImagesListCell else {
            return UITableViewCell()
        }
        cell.selectionStyle = .none
        let photo = photos[indexPath.row]
        cell.configure(with: photo)
        cell.onLikeTapped = { [weak self] in
            self?.likeIsTapped(for: photo, indexPath: indexPath)
        }
        
        return cell
    }
    
    private func likeIsTapped(for photo: Photo, indexPath: IndexPath) {
        UIBlockingProgressHUD.show()
        
        let photoId = photo.id
        let isLiked = photo.isLiked
        
        imagesListService.changeLike(photoId: photoId, isLike: isLiked) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            switch result {
            case .success:
                self?.photos[indexPath.row].toggleLike()
                self?.tableView.reloadRows(at: [indexPath], with: .automatic)
            case .failure(let failure):
                print(failure.localizedDescription)
            }
        }

    }
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == photos.count {
            imagesListService.fetchPhotosNextPage()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            let photo = photos[indexPath.row]
            
            let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
            let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
            let imageWidth = photo.size.width
            let scale = imageViewWidth / imageWidth
            let cellHeight = photo.size.height * scale + imageInsets.top + imageInsets.bottom
            return cellHeight
        }
}

// MARK: - Helpers
extension ImagesListViewController {
    @objc private func updateTableViewAnimated() {
        print(#function)
        
        let oldCount = photos.count
        let newCount = imagesListService.photos.count
        photos = imagesListService.photos
        tableView.reloadData()
//        if oldCount != newCount {
//            tableView.performBatchUpdates {
//                let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
//                tableView.insertRows(at: indexPaths, with: .automatic)
//            } completion: { _ in
////                print("🔵 [ImagesListViewController] Таблица обновлена, добавлено \(newCount - oldCount) строк")
//            }
//        }
    }
}



//// //// / 032------------
extension ImagesListViewController: ImagesListView {
    func reload() {
        updateTableViewAnimated()
    }
    
    func showError(_ message: String) {
        
    }
}

protocol ImagesListView: AnyObject {
    func reload()
    func showError(_ message: String)
}

protocol ImagesListPresenter {
    func viewDidLoad()
    func changeLike(photoId: String, isLike: Bool)
    func imageTapped(photoId: String)
}

class ImagesListPresenterImpl: ImagesListPresenter {
    weak var view: ImagesListView?
    let imageService: ImageService
    var page: Int = 0
    
    init(
        view: ImagesListView,
        imageService: ImageService
    ) {
        self.view = view
        self.imageService = imageService
    }
    
    func viewDidLoad() {
        loadImages()
    }
    
    func changeLike(photoId: String, isLike: Bool) {
        
    }
    
    func imageTapped(photoId: String) {
        
    }
    
    private func loadImages() {
        imageService.loadImages { [weak self] result in
            switch result {
            case .success(let success):
                self?.view?.reload()
                self?.page += 10
                
            case .failure(let failure):
                self?.view?.showError(failure.localizedDescription)
            }
        }
    }
}

protocol ImageService {
    func loadImages(completion: (Result<Void, Error>) -> Void)
}

class ImageServiceImpl: ImageService {
    func loadImages(completion: (Result<Void, any Error>) -> Void) {
        completion(.success(()))
    }
}
