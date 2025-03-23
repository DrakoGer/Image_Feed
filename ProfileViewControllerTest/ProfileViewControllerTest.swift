//
//  ProfileViewControllerTest.swift
//  ProfileViewControllerTest
//
//  Created by Yura on 22.03.25.
//

import XCTest
@testable import Image_Feed

// MARK: - Tests
final class ProfileViewControllerTests: XCTestCase {
    var controller: ProfileViewController!
    var presenter: ProfilePresenterSpy!
    
    override func setUp() {
        super.setUp()
        presenter = ProfilePresenterSpy()
        controller = ProfileViewController()
        controller.presenter = presenter
        presenter.view = controller
        controller.viewDidLoad()
    }
    
    override func tearDown() {
        controller = nil
        presenter = nil
        super.tearDown()
    }
    
    func testViewControllerCallsViewDidLoad() {

        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
    
    func testViewControllerCallsDidTapLogoutButton() {
        controller.invokeLogoutButtonTapped()
        
        XCTAssertTrue(presenter.didTapLogoutButtonCalled)
    }
    
    func testPresenterUpdatesProfileDetails() {
        // Given
        let controller = ProfileViewControllerSpy()
        let presenter = ProfilePresenterSpy()
        presenter.view = controller
        let name = "Test Name"
        let login = "@testuser"
        let description = "Test Bio"
        
        // When
        presenter.view?.updateProfileDetails(name: name, login: login, description: description)
        
        // Then
        XCTAssertTrue(controller.updateProfileDetailsCalled)
        XCTAssertEqual(controller.updatedName, name)
        XCTAssertEqual(controller.updatedLogin, login)
        XCTAssertEqual(controller.updatedDescription, description)
    }
    
    func testPresenterUpdatesAvatar() {
        // Given
        let controller = ProfileViewControllerSpy()
        let presenter = ProfilePresenterSpy()
        presenter.view = controller
        let url = URL(string: "https://example.com/avatar.jpg")!
        
        // When
        presenter.view?.updateAvatar(url: url)
        
        // Then
        XCTAssertTrue(controller.updateAvatarCalled)
        XCTAssertEqual(controller.updatedAvatarURL, url)
    }
    
    func testPresenterShowsLogoutAlert() {
        // Given
        let controller = ProfileViewControllerSpy()
        let presenter = ProfilePresenterSpy()
        presenter.view = controller
        var completionCalled = false
        let completion: () -> Void = {
            completionCalled = true
        }
        
        presenter.view?.showLogoutAlert(completion: completion)
        XCTAssertTrue(controller.showLogoutAlertCalled)
        XCTAssertNotNil(controller.logoutAlertCompletion)
        
        controller.logoutAlertCompletion?()
        XCTAssertTrue(completionCalled)
    }
}

// MARK: - Mocks
final class ProfileViewControllerSpy: UIViewController, ProfileViewControllerProtocol {
    var presenter: ProfilePresenterProtocol?
    
    var updateProfileDetailsCalled = false
    var updatedName: String?
    var updatedLogin: String?
    var updatedDescription: String?
    
    var updateAvatarCalled = false
    var updatedAvatarURL: URL?
    
    var showLogoutAlertCalled = false
    var logoutAlertCompletion: (() -> Void)?
    
    func updateProfileDetails(name: String, login: String, description: String?) {
        updateProfileDetailsCalled = true
        updatedName = name
        updatedLogin = login
        updatedDescription = description
    }
    
    func updateAvatar(url: URL?) {
        updateAvatarCalled = true
        updatedAvatarURL = url
    }
    
    func showLogoutAlert(completion: @escaping () -> Void) {
        showLogoutAlertCalled = true
        logoutAlertCompletion = completion
    }
}

final class ProfilePresenterSpy: ProfilePresenterProtocol {
    var view: ProfileViewControllerProtocol?
    
    var viewDidLoadCalled = false
    var didTapLogoutButtonCalled = false
    var logoutCalled = false
    
    func viewDidLoad() {
        viewDidLoadCalled = true
    }
    
    func didTapLogoutButton() {
        didTapLogoutButtonCalled = true
    }
    
    func logout() {
        logoutCalled = true
    }
}

// MARK: - Extension for Test Access
extension ProfileViewController {
    @objc func invokeLogoutButtonTapped() {
        performSelector(onMainThread: NSSelectorFromString("logoutButtonTapped"), with: nil, waitUntilDone: true)
    }
}
