//
//  ViewController.swift
//  ImageFeed
//
//  Created by Yura on 23.12.24.
//

import UIKit
import Kingfisher

final class ImagesListViewController: UIViewController, ImagesListViewControllerProtocol {
    
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    
    // MARK: - Outlets
    @IBOutlet private weak var tableView: UITableView!
    
    
    // MARK: - Properties
    private var photos: [Photo] = []
    var presenter: ImagesListPresenterProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        presenter = ImagesListPresenter()
        presenter?.view = self
        presenter?.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard let viewController = segue.destination as? SingleImageViewController,
                  let indexPath = sender as? IndexPath else {
                assertionFailure("Invalid segue destination")
                return
            }
            let photo = presenter?.getPhoto(at: indexPath.row) // Используем presenter
            viewController.imageURL = URL(string: photo?.largeImageURL ?? "")
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    func updateTableView(with newPhotos: [Photo]) {
        let oldCount = photos.count
        photos.append(contentsOf: newPhotos)
        let newCount = photos.count
        updateTableViewAnimated(oldCount: oldCount, newCount: newCount)
    }
    
    func reloadRows(at indexPaths: [IndexPath]) {
        // Обновляем photos перед перерисовкой
        for indexPath in indexPaths {
            if let photo = presenter?.getPhoto(at: indexPath.row) {
                photos[indexPath.row] = photo
            }
        }
        tableView.reloadRows(at: indexPaths, with: .automatic)
    }
    
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func updateTableViewAnimated(oldCount: Int, newCount: Int) {
        if newCount > oldCount {
            let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
            tableView.insertRows(at: indexPaths, with: .automatic)
        } else {
            tableView.reloadData()
        }
    }
}

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
            self?.presenter?.didTapLikeButton(at: indexPath.row)
        }
        return cell
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presenter?.didSelectPhoto(at: indexPath.row)
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == photos.count {
            presenter?.fetchPhotos()
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
