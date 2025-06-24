//
//  SplashViewController.swift
//  FitConnect
//
//  Created by Can Acar on 4/25/25.
//

import UIKit
import SwiftUI

class SplashViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1.0) // #0D0F14
        
        // Embed SwiftUI SplashView
        let splashView = SplashView(onContinue: { [weak self] in
            self?.transitionToMainApp()
        })
        
        let hostingController = UIHostingController(rootView: splashView)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func transitionToMainApp() {
        // Transition to the main app flow
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let mainViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController") as? UIViewController {
            mainViewController.modalPresentationStyle = .fullScreen
            self.present(mainViewController, animated: true, completion: nil)
        } else {
            // Use availability check for LoginViewController
            if #available(iOS 16.0, *) {
                let loginViewController = LoginViewController()
                loginViewController.modalPresentationStyle = .fullScreen
                self.present(loginViewController, animated: true, completion: nil)
            }
        }
    }
}
