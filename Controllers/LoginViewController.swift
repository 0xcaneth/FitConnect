//
//  LoginViewController.swift
//  FitConnect
//
//  Created by Can Acar on 4/25/25.
//

import UIKit
import SwiftUI

@available(iOS 16.0, *)
class LoginViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    @available(iOS 16.0, *)
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1.0) // #0D0F14
        
        // Embed SwiftUI LoginView
        let loginView = LoginScreenView(
            onSignUpTap: { [weak self] in
                self?.navigateToSignUp()
            },
            onForgotPasswordTap: { [weak self] in
                self?.navigateToForgotPassword()
            },
            onBack: { [weak self] in
                self?.navigateBack()
            }
        )
        
        let hostingController = UIHostingController(rootView: loginView)
        
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
    
    private func navigateToSignUp() {
        // Navigate to sign up view
        print("Navigate to sign up")
    }
    
    private func navigateToForgotPassword() {
        // Navigate to forgot password view
        print("Navigate to forgot password")
    }
    
    private func navigateBack() {
        // Navigate back
        dismiss(animated: true, completion: nil)
    }
}
