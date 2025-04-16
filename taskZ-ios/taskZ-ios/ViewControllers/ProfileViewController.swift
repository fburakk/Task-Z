//
//  ProfileViewController.swift
//  taskZ-ios
//
//  Created by Burak Köse on 23.03.2025.
//

import UIKit

class ProfileViewController: UIViewController {
    
    // MARK: - UI Elements
    private let profileView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
        view.layer.cornerRadius = 30
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let initialsLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let userInfoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        return label
    }()
    
    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let editButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = UIColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.backgroundColor = .clear
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    // MARK: - Properties
    private let sections = [
        Section(title: "WORKSPACES", items: [
            MenuItem(title: "Your Workspaces", hasDisclosure: true),
            MenuItem(title: "Guest Workspaces", hasDisclosure: true)
        ]),
        Section(title: "SETTINGS & TOOLS", items: [
            MenuItem(title: "Account Settings", hasDisclosure: false),
            MenuItem(title: "Notifications", hasDisclosure: false),
            MenuItem(title: "Privacy & Security", hasDisclosure: false),
            MenuItem(title: "Language", hasDisclosure: false),
            MenuItem(title: "Help & Support", hasDisclosure: false),
            MenuItem(title: "About", hasDisclosure: false),
            MenuItem(title: "Logout", hasDisclosure: false)
        ])
    ]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupTabBar()
        updateUserInfo()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .black
        title = "Profile"
        
        view.addSubview(profileView)
        profileView.addSubview(avatarView)
        avatarView.addSubview(initialsLabel)
        profileView.addSubview(userInfoStackView)
        profileView.addSubview(editButton)
        view.addSubview(tableView)
        
        userInfoStackView.addArrangedSubview(nameLabel)
        userInfoStackView.addArrangedSubview(nicknameLabel)
        userInfoStackView.addArrangedSubview(emailLabel)
        
        NSLayoutConstraint.activate([
            profileView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            profileView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            profileView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            profileView.heightAnchor.constraint(equalToConstant: 120),
            
            avatarView.leadingAnchor.constraint(equalTo: profileView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: profileView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 60),
            avatarView.heightAnchor.constraint(equalToConstant: 60),
            
            initialsLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            userInfoStackView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 16),
            userInfoStackView.centerYAnchor.constraint(equalTo: profileView.centerYAnchor),
            userInfoStackView.trailingAnchor.constraint(equalTo: editButton.leadingAnchor, constant: -16),
            
            editButton.centerYAnchor.constraint(equalTo: profileView.centerYAnchor),
            editButton.trailingAnchor.constraint(equalTo: profileView.trailingAnchor, constant: -16),
            editButton.widthAnchor.constraint(equalToConstant: 44),
            editButton.heightAnchor.constraint(equalToConstant: 44),
            
            tableView.topAnchor.constraint(equalTo: profileView.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func updateUserInfo() {
        if let username = UserDefaultsManager.shared.username {
            nameLabel.text = username
            // Get initials from username
            let initials = username.split(separator: " ")
                .prefix(2)
                .compactMap { $0.first }
                .map(String.init)
                .joined()
            initialsLabel.text = initials.uppercased()
            
            // Use username as nickname if no separate nickname field
            nicknameLabel.text = "@\(username.lowercased().replacingOccurrences(of: " ", with: ""))"
        }
        
        if let email = UserDefaultsManager.shared.email {
            emailLabel.text = email
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    private func setupTabBar() {
        tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person"), tag: 2)
    }
}

// MARK: - TableView DataSource & Delegate
extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = sections[indexPath.section].items[indexPath.row]
        
        var config = UIListContentConfiguration.cell()
        config.text = item.title
        config.textProperties.color = .white
        cell.contentConfiguration = config
        
        cell.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        
        if item.hasDisclosure {
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = .gray
            header.textLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = sections[indexPath.section].items[indexPath.row]
        if item.title == "Logout" {
            UserDefaultsManager.shared.clearUserSession()
            
            // Present login screen
            let loginVC = LoginViewController()
            let navController = UINavigationController(rootViewController: loginVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
    }
}

// MARK: - Models
struct Section {
    let title: String
    let items: [MenuItem]
}

struct MenuItem {
    let title: String
    let hasDisclosure: Bool
}
