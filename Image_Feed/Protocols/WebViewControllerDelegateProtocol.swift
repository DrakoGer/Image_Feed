//
//  WebViewControllerDelegateProtocol.swift
//  Image_Feed
//
//  Created by Yura on 17.02.25.
//

import UIKit
import WebKit

protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
    func webViewViewControllerDidCancel(_ vc:WebViewViewController)
}
