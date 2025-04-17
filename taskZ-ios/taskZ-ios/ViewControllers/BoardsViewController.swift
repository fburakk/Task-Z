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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTabBar()
        updateWelcomeMessage()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        navigationItem.hidesBackButton = true
        
        view.addSubview(welcomeLabel)
        
        NSLayoutConstraint.activate([
            welcomeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            welcomeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            welcomeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }
    
    private func setupTabBar() {
        tabBarItem = UITabBarItem(title: "Panolar", image: UIImage(systemName: "mail.stack"), tag: 0)
    }
    
    private func updateWelcomeMessage() {
        if let username = UserDefaultsManager.shared.username {
            welcomeLabel.text = "Welcome, \(username)!"
        } else {
            welcomeLabel.text = "Welcome to TaskZ!"
        }
    }
}

