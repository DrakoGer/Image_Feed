//
//  SingleImageViewController.swift
//  Image_Feed
//
//  Created by Yura on 17.01.25.
//

import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {
    
    var image: UIImage? {
        didSet {
            guard isViewLoaded, let image else { return }
            imageView.image = image
            imageView.frame.size = image.size
            rescaleAndCenterImageInScrollView(image: image)
            centerImageInScrollView()
        }
    }
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    var imageUrl: String?
    private let placeholderImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "placeHolderStubForSingleImage"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    var imageURL: URL? {
        didSet {
            guard isViewLoaded else { return }
            loadImage()
        }
    }
    
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        view.layoutIfNeeded()
        
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        let scale = min(maxZoomScale, max(minZoomScale, min(hScale, vScale)))
        
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        
        let newContentSize = scrollView.contentSize
        let x = (newContentSize.width - visibleRectSize.width) / 2
        let y = (newContentSize.height - visibleRectSize.height) / 2
        scrollView.setContentOffset(CGPoint(x: x, y: y), animated: false)
    }
    
    private func setupPlaceholderConstraints() {
        imageView.addSubview(placeholderImageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            placeholderImageView.widthAnchor.constraint(equalToConstant: 83),
            placeholderImageView.heightAnchor.constraint(equalToConstant: 75),
            placeholderImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func removePlaceholder() {
        placeholderImageView.removeFromSuperview()
    }
    
    private func centerImageInScrollView() {
        guard let imageView = imageView else { return }
        
        let scrollViewSize = scrollView.bounds.size
        let imageSize = imageView.frame.size
        
        let horizontalInset = max(0, (scrollViewSize.width - imageSize.width) / 2)
        let verticalInset = max(0, (scrollViewSize.height - imageSize.height) / 2)
        
        scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        scrollView.delegate = self
        
        loadImage()
    }
    
    @IBAction func didTapBackButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapShareButton(_ sender: Any) {
        guard let image else { return }
        let share = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        present(share, animated: true, completion: nil)
    }
    
    private func loadImage() {
        guard let url = imageURL else {
            print("[SingleImageViewController|loadImage]: Некорректный URL изображения")
            return
        }
        
        UIBlockingProgressHUD.show()
        
        imageView.kf.setImage(
            with: url,
            placeholder: nil,
            options: [
                .cacheOriginalImage,
                .transition(.fade(0.2))
            ]) { [weak self] result in
                guard let self = self else { return }
                UIBlockingProgressHUD.dismiss()
                
                switch result {
                case .success(let imageResult):
                    self.imageView.image = imageResult.image
                    self.removePlaceholder() // Удаляем заглушку после успешной загрузки
                    self.rescaleAndCenterImageInScrollView(image: imageResult.image)
                    print("Изображение загружено: \(imageResult.image.size)")
                case .failure(let error):
                    print("[SingleImageViewController|loadImage]: Ошибка загрузки: \(error.localizedDescription)")
                    self.imageView.image = nil
                    self.setupPlaceholderConstraints() // Показываем заглушку в случае ошибки
                    self.showSingleImageLoadError()
                }
            }
    }
    
    private func showSingleImageLoadError() {
        let alert = UIAlertController(title: "Ошибка!", message: "Что-то пошло не так, попробовать еще раз?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Нет", style: .cancel))
        alert.addAction(UIAlertAction(title: "Да", style: .default) { _ in
            self.loadImage()
        })
        present(alert, animated: true)
    }
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}
