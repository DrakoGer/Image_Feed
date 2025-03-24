//
//  ImageListTests.swift
//  ImageListTests
//
//  Created by Yura on 21.03.25.
//

import XCTest
@testable import Image_Feed


final class ImagesListPresenterTests: XCTestCase {
    var sut: ImagesListPresenter!
    var viewSpy: ImagesListViewControllerSpy!
    var serviceSpy: ImagesListServiceSpy!
    
    override func setUp() {
        super.setUp()
        viewSpy = ImagesListViewControllerSpy()
        serviceSpy = ImagesListServiceSpy()
        sut = ImagesListPresenter(imagesListService: serviceSpy)
        sut.view = viewSpy
    }
    
    override func tearDown() {
        sut = nil
        viewSpy = nil
        serviceSpy = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testViewDidLoad_CallsFetchPhotos() {
        sut.viewDidLoad()
        
        XCTAssertTrue(serviceSpy.fetchPhotosNextPageCalled)
    }
    
    func testFetchPhotos_CallsService() {
        sut.fetchPhotos()
        
        XCTAssertTrue(serviceSpy.fetchPhotosNextPageCalled)
    }
    
    func testDidTapLikeButton_Success() {
        let photo = Photo(id: "1", size: CGSize(width: 100, height: 100), createdAt: nil, welcomeDescription: nil, thumbImageURL: "", largeImageURL: "", fullImageURL: "", isLiked: false)
        serviceSpy.photos = [photo]
        sut.viewDidLoad() // Устанавливаем наблюдатель
        NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil) // Синхронизируем photos
        
        let expectation = XCTestExpectation(description: "Waiting for changeLike completion")
        sut.didTapLikeButton(at: 0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(serviceSpy.changeLikeCalled)
        XCTAssertTrue(viewSpy.reloadRowsCalled)
        XCTAssertEqual(viewSpy.reloadedIndexPaths, [IndexPath(row: 0, section: 0)])
    }
    
    func testDidTapLikeButton_Failure() {
        let photo = Photo(id: "1", size: CGSize(width: 100, height: 100), createdAt: nil, welcomeDescription: nil, thumbImageURL: "", largeImageURL: "", fullImageURL: "", isLiked: false)
        serviceSpy.photos = [photo]
        serviceSpy.shouldFailChangeLike = true
        sut.viewDidLoad() // Устанавливаем наблюдатель
        NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil) // Синхронизируем photos
        
        let expectation = XCTestExpectation(description: "Waiting for changeLike completion with error")
        sut.didTapLikeButton(at: 0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 4.0)
        XCTAssertTrue(serviceSpy.changeLikeCalled)
        XCTAssertTrue(viewSpy.showErrorCalled)
    }
    
    func testDidSelectPhoto_DoesNotCrash() {
        sut.didSelectPhoto(at: 0)
        
        XCTAssertTrue(true)
    }
    
    func testPhotoAtIndexPath_ReturnsCorrectPhoto() {
        let photo = Photo(id: "testPhotoId", size: CGSize(width: 100, height: 100), createdAt: nil, welcomeDescription: nil, thumbImageURL: "", largeImageURL: "", fullImageURL: "", isLiked: false)
        serviceSpy.photos = [photo]
        sut.viewDidLoad()
        NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil) // Синхронизируем photos
        
        let indexPath = IndexPath(row: 0, section: 0)
        let returnedPhoto = sut.photo(at: indexPath)
        
        XCTAssertEqual(returnedPhoto.id, "testPhotoId")
    }
    
    func testGetPhotoAtIndex_ReturnsCorrectPhoto() {
        let photo = Photo(id: "testPhotoId", size: CGSize(width: 100, height: 100), createdAt: nil, welcomeDescription: nil, thumbImageURL: "", largeImageURL: "", fullImageURL: "", isLiked: false)
        serviceSpy.photos = [photo]
        sut.viewDidLoad() // Устанавливаем наблюдатель
        NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil) // Синхронизируем photos
        
        let returnedPhoto = sut.getPhoto(at: 0)
        
        XCTAssertEqual(returnedPhoto.id, "testPhotoId")
    }
    
    func testGetPhotosCount_ReturnsCorrectCount() {
        let photos = [            Photo(id: "1", size: CGSize(width: 100, height: 100), createdAt: nil, welcomeDescription: nil, thumbImageURL: "", largeImageURL: "", fullImageURL: "", isLiked: false),            Photo(id: "2", size: CGSize(width: 100, height: 100), createdAt: nil, welcomeDescription: nil, thumbImageURL: "", largeImageURL: "", fullImageURL: "", isLiked: false)        ]
        serviceSpy.photos = photos
        sut.viewDidLoad() // Устанавливаем наблюдатель
        NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil) // Синхронизируем photos
        
        let count = sut.getPhotosCount()
        
        XCTAssertEqual(count, 2)
    }
}

// MARK: - Mocks
final class ImagesListViewControllerSpy: ImagesListViewControllerProtocol {
    var presenter: ImagesListPresenterProtocol?
    var updateTableViewCalled = false
    var updatedPhotos: [Photo]?
    var reloadRowsCalled = false
    var reloadedIndexPaths: [IndexPath]?
    var showErrorCalled = false
    var showErrorMessage: String?
    var updatePhotosCalled = false
    var showLikeErrorCalled = false
    
    func updateTableView(with newPhotos: [Photo]) {
        updateTableViewCalled = true
        updatedPhotos = newPhotos
    }
    
    func reloadRows(at indexPaths: [IndexPath]) {
        reloadRowsCalled = true
        reloadedIndexPaths = indexPaths
    }
    
    func showError(_ message: String) {
        showErrorCalled = true
        showErrorMessage = message
    }
    
    func updatePhotos() {
        updatePhotosCalled = true
    }
    
    func showLikeError() {
        showLikeErrorCalled = true
    }
}

final class ImagesListServiceSpy: ImagesListServiceProtocol {
    static var didChangeNotification: Notification.Name = .init("ImagesListServiceDidChange")
    var photos: [Photo] = []
    var fetchPhotosNextPageCalled = false
    var changeLikeCalled = false
    var shouldFailChangeLike = false
    
    func fetchPhotosNextPage() {
        fetchPhotosNextPageCalled = true
    }
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        changeLikeCalled = true
        DispatchQueue.main.async {
            if self.shouldFailChangeLike {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Test error"])))
            } else {
                completion(.success(()))
            }
        }
    }
}
