//  WebViewPresenter.swift
//
//  Image_Feed
//
//  Created by Yura on 20.03.25.
//

import Foundation

public protocol WebViewViewControllerProtocol: AnyObject {
    var presenter: WebViewPresenterProtocol? { get set }
    func load(request: URLRequest)
    func setProgressValue(_ newValue: Float)
    func setProgressHidden(_ isHidden: Bool)
}

public protocol WebViewPresenterProtocol {
    var view: WebViewViewControllerProtocol? { get set }
    func viewDidLoad()
    func didUpdateProgressValue(_ newValue: Double)
    func code(from url: URL) -> String?
}

final class WebViewPresenterImpl: WebViewPresenterProtocol {
    
    var authHelper: AuthHelperProtocol
    
    init(authHelper: AuthHelperProtocol, view: WebViewViewControllerProtocol? = nil) {
        self.authHelper = authHelper
        self.view = view
    }

    weak public var view: WebViewViewControllerProtocol?
        
    public func viewDidLoad() {
        guard let request = authHelper.authRequest() else {
            return
        }
            
        didUpdateProgressValue(0)
        view?.load(request: request)
    }
    
    public func didUpdateProgressValue(_ newValue: Double) {
        let newProgresValue = Float(newValue)
        view?.setProgressValue(newProgresValue)
        
        let shouldHideProgress = shouldHideProgress(for: newProgresValue)
        view?.setProgressHidden(shouldHideProgress)
    }
    
    func shouldHideProgress(for value: Float) -> Bool {
        abs(value - 1.0) <= 0.0001
    }
    
    public func code(from url: URL) -> String? {
        authHelper.code(from: url)
    }

}
