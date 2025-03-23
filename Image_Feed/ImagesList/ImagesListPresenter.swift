//
//  ImagesListPresenter.swift
//  Image_Feed
//
//  Created by Yura on 21.03.25.
//

import Foundation

protocol ImagesListViewControllerProtocol: AnyObject {
    var presenter: ImagesListPresenterProtocol? { get set }
    func updateTableView(with newPhotos: [Photo])
    func reloadRows(at indexPaths: [IndexPath])
    func showError(_ message: String)
}

protocol ImagesListPresenterProtocol {
    var view: ImagesListViewControllerProtocol? { get set }
    func viewDidLoad()
    func fetchPhotos()
    func didSelectPhoto(at index: Int)
    func didTapLikeButton(at index: Int)
    func getPhoto(at index: Int) -> Photo
    func getPhotosCount() -> Int
}

protocol ImagesListServiceProtocol {
    var photos: [Photo] { get }
    static var didChangeNotification: Notification.Name { get }
    func fetchPhotosNextPage()
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void)
}

extension ImagesListService: ImagesListServiceProtocol {}


final class ImagesListPresenter: ImagesListPresenterProtocol {
    func getPhotosCount() -> Int {
        return photos.count
    }
    
    func getPhoto(at index: Int) -> Photo {
        return photos[index]
    }

    weak var view: ImagesListViewControllerProtocol?
    private let imagesListService: ImagesListServiceProtocol
    private var photos: [Photo] = []
    
    init(imagesListService: ImagesListServiceProtocol = ImagesListService.shared) {
        self.imagesListService = imagesListService
    }
    
    func viewDidLoad() {
        fetchPhotos()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updatePhotos),
            name: ImagesListService.didChangeNotification,
            object: nil
        )
    }
    
    func fetchPhotos() {
        imagesListService.fetchPhotosNextPage()
    }
    
    @objc private func updatePhotos() {
        let oldCount = photos.count
        photos = imagesListService.photos
        let newCount = photos.count
        if newCount > oldCount {
            let newPhotos = photos[oldCount..<newCount].map { $0 }
            view?.updateTableView(with: Array(newPhotos))
        } else {
            view?.updateTableView(with: photos)
        }
    }
    
    func didSelectPhoto(at index: Int) {
    }
    
    func photo(at indexPath: IndexPath) -> Photo {
        return photos[indexPath.row]
    }
    
    func didTapLikeButton(at index: Int) {
        UIBlockingProgressHUD.show()
        
        let photo = photos[index]
        let newLikeState = !photo.isLiked
        
        imagesListService.changeLike(photoId: photo.id, isLike: photo.isLiked) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self = self else { return }
            switch result {
            case .success:
                self.photos[index].toggleLike()
                self.view?.reloadRows(at: [IndexPath(row: index, section: 0)])
            case .failure(let error):
                self.view?.showError(error.localizedDescription)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
