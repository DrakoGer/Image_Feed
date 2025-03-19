//
//  Image_FeedTests.swift
//  Image_FeedTests
//
//  Created by Yura on 16.03.25.
//

import XCTest
@testable import Image_Feed

class MockImageServiceImpl: ImageService {
    var error: Error?
    
    init(error: Error?) {
        self.error = error
    }
    
    func loadImages(completion: (Result<Void, any Error>) -> Void) {
        if let error {
            completion(.failure(NSError(domain: "avoe", code: 1, userInfo: [:])))
            return
        }
        
        completion(.success(()))
    }
}

class SpyImagesListView: ImagesListView {
    var reloadCalled = false
    var showErrorCalled = false
    
    func reload() {
        reloadCalled = true
    }
    
    func showError(_ message: String) {
        showErrorCalled = true
    }
}


class UnitTest: XCTestCase {
    var sut: ImagesListPresenterImpl!
    var imageService: MockImageServiceImpl!
    var view: SpyImagesListView!
    
    override func setUp() {
        super.setUp()
        imageService = MockImageServiceImpl(error: nil)
        view = SpyImagesListView()
        sut = ImagesListPresenterImpl(view: view, imageService: imageService)
    }
    
    override func tearDown() {
        super.tearDown()
        sut = nil
        view = nil
        imageService = nil
    }
    
    func test_reloadIsCalledOnSuccess() {
        sut.viewDidLoad()
        
        XCTAssertTrue(view.reloadCalled)
    }
    
    func test_showErrorIsCalledOnFailure() {
        imageService.error = NSError(domain: "", code: 0, userInfo: nil)
        sut.viewDidLoad()
        
        XCTAssertTrue(view.showErrorCalled)
        XCTAssertEqual(view.reloadCalled, false)
    }
    
    func test_pageLoadEqual10() {
        
        sut.viewDidLoad()
        
        XCTAssertEqual(sut.page, 10)
        
        sut.viewDidLoad()
        
        XCTAssertEqual(sut.page, 20)
    }
    
    func test_pageLoadError() {
        imageService.error = NSError(domain: "", code: 0, userInfo: nil)
        
        sut.viewDidLoad()
        
        XCTAssertEqual(sut.page, 0)
        XCTAssertTrue(view.showErrorCalled)        
    }
}
