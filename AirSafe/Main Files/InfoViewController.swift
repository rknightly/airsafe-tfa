//
//  InfoViewController.swift
//  AirSafe
//
//  Created by Ryan Knightly on 8/16/19.
//  Copyright © 2019 Ryan Knightly. All rights reserved.
//

import Foundation
import UIKit
import WebKit


class InfoViewController: UIViewController, WKUIDelegate {

    var webView: WKWebView!
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string: Config.INFO_URL_WEB_SERVICE)!
        URLSession.shared.dataTask(with: url) { (result) in
            switch result {
            case .success( _, let data):
                // Handle Data and Response
                let urlString = String(data:data, encoding: .ascii)
                let infoPageUrl = URL(string:urlString!)
                let myRequest = URLRequest(url: infoPageUrl!)
                DispatchQueue.main.async {
                    self.webView.load(myRequest)
                }
                break
            case .failure(let error):
                // Handle Error
                print(error)
                break
            }
        }.resume()
    }
}
