//
//  Image_FeedTests.swift
//  Image_FeedTests
//
//  Created by Yura on 16.03.25.
//


import XCTest
@testable import Image_Feed

final class WebViewTests: XCTestCase {

    func testViewControllerCallsViewDidLoad() {

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "WebViewViewController") as! WebViewViewController
        let presenterSpy = WebViewPresenterSpy()
        viewController.presenter = presenterSpy
        presenterSpy.view = viewController

        viewController.loadViewIfNeeded()
        
        XCTAssertTrue(presenterSpy.viewDidLoadCalled)
    }
    
    //Самостоятельная задача 1
    func testPresenterCallsLoadRequest() {

        let spyView = WebViewControllerSpy()
        let authHelper = MockAuthHelper(request: .init(url: URL(string: "https://google.com")!))
        let presenter = WebViewPresenterImpl(authHelper: authHelper, view: spyView)
        spyView.presenter = presenter
        
        presenter.viewDidLoad()
        
        XCTAssertTrue(spyView.loadRequestCalled)
    }
    
    //Самостоятельная задача 2
    func testProgressVisibleWhenLessThenOne() {
        let authHelper = MockAuthHelper()
        let presenter = WebViewPresenterImpl(authHelper: authHelper)
        let progress: Float = 1
        
        let shouldHideProgress = presenter.shouldHideProgress(for: progress)
        
        XCTAssertTrue(shouldHideProgress)
    }
    
    func testAuthHelperAuthURL() {
        let configuration = AuthConfiguration.standard
        let authHelper = AuthHelper(configuration: configuration)
        
        let url = authHelper.authURL()
        let urlString = url!.absoluteString
        
        XCTAssertTrue(urlString.contains(configuration.authURLString))
        XCTAssertTrue(urlString.contains(configuration.accessKey))
        XCTAssertTrue(urlString.contains(configuration.redirectUri))
        XCTAssertTrue(urlString.contains("code"))
        XCTAssertTrue(urlString.contains(configuration.accessScope))
    }
    
    //Самостоятельная задача 3
    func testCodeFrumURL() {
        var urlComponents = URLComponents(string: "https://unsplash.com/oauth/authorize/native")!
        urlComponents.queryItems = [URLQueryItem(name: "code", value: "test code")]
        let url = urlComponents.url!
        let authHelper = AuthHelper()
        
        let code = authHelper.code(from: url)
        
        XCTAssertEqual(code, "test code")
    }
}

    


    
class MockAuthHelper: AuthHelperProtocol {
    let request: URLRequest?
    
    init(request: URLRequest? = nil) {
        self.request = request
    }
    
    func authRequest() -> URLRequest? {
        request
    }
    
    func code(from url: URL) -> String? {
        nil
    }
}

class WebViewControllerSpy: WebViewViewControllerProtocol {
    var presenter: WebViewPresenterProtocol?
    
    var progresValue = 0.6
    var loadRequestCalled = false
    
    func load(request: URLRequest) {
        loadRequestCalled = true
    }
    
    func setProgressValue(_ newValue: Float) {
        progresValue
    }
    
    func setProgressHidden(_ isHidden: Bool) { }
}

class WebViewPresenterSpy: WebViewPresenterProtocol {
    
    var viewDidLoadCalled = false
    var didUpdateProgressValueIsCalled = false
    
    var view: WebViewViewControllerProtocol?
        
    func viewDidLoad() {
        viewDidLoadCalled = true
    }
    
    func didUpdateProgressValue(_ newValue: Double) {
        didUpdateProgressValueIsCalled = true
    }
    
    func code(from url: URL) -> String? {
        nil
    }
}


