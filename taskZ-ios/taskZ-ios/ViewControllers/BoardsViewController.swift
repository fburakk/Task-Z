//
//  BoardsViewController.swift
//  taskZ-ios
//
//  Created by Burak Köse on 22.03.2025.
//

import UIKit

class BoardsViewController: UIViewController {
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Logout", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.6, green: 0.6, blue: 0.8, alpha: 1.0)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        updateWelcomeMessage()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        navigationItem.hidesBackButton = true
        
        view.addSubview(welcomeLabel)
        view.addSubview(logoutButton)
        
        NSLayoutConstraint.activate([
            welcomeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            welcomeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            welcomeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            logoutButton.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 20),
            logoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            logoutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupActions() {
        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
    }
    
    private func updateWelcomeMessage() {
        if let username = UserDefaultsManager.shared.username {
            welcomeLabel.text = "Welcome, \(username)!"
        } else {
            welcomeLabel.text = "Welcome to TaskZ!"
        }
    }
    
    @objc private func logoutButtonTapped() {
        UserDefaultsManager.shared.clearUserSession()
        
        // Present login screen
        let loginVC = LoginViewController()
        let navController = UINavigationController(rootViewController: loginVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
}

