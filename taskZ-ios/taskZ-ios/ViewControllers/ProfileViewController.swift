//
//  ProfileViewController.swift
//  taskZ-ios
//
//  Created by Burak Köse on 23.03.2025.
//

import UIKit

class ProfileViewController: UIViewController {
    
    // MARK: - UI Elements
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.backgroundColor = .clear
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    // MARK: - Properties
    private let sections = [
        Section(title: "", items: [
            MenuItem(title: "", hasDisclosure: false, isProfile: true)
        ]),
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
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .black
        title = "Profile"
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: "ProfileCell")
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
        return sections[section].title.isEmpty ? nil : sections[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        
        if item.isProfile {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath) as! ProfileTableViewCell
            cell.configure(with: UserDefaultsManager.shared.username ?? "", email: UserDefaultsManager.shared.email ?? "")
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        var config = UIListContentConfiguration.cell()
        config.text = item.title
        config.textProperties.color = item.title == "Logout" ? .red : .white
        cell.contentConfiguration = config
        
        cell.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        
        if item.hasDisclosure {
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = sections[indexPath.section].items[indexPath.row]
        return item.isProfile ? 90 : UITableView.automaticDimension
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
            navController.modalTransitionStyle = .crossDissolve
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
    var isProfile: Bool = false
}

// MARK: - ProfileTableViewCell
class ProfileTableViewCell: UITableViewCell {
    private let avatarView: UIView = {
        let view = UIView()
        view.backgroundColor = .cyan
        view.layer.cornerRadius = 25
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let initialsLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 20, weight: .bold)
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
    
    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let editButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = .cyan
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        
        contentView.addSubview(avatarView)
        avatarView.addSubview(initialsLabel)
        contentView.addSubview(userInfoStackView)
        contentView.addSubview(editButton)
        
        userInfoStackView.addArrangedSubview(nicknameLabel)
        userInfoStackView.addArrangedSubview(emailLabel)
        
        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 50),
            avatarView.heightAnchor.constraint(equalToConstant: 50),
            
            initialsLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            userInfoStackView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 16),
            userInfoStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            userInfoStackView.trailingAnchor.constraint(equalTo: editButton.leadingAnchor, constant: -16),
            
            editButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            editButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            editButton.widthAnchor.constraint(equalToConstant: 44),
            editButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    func configure(with username: String, email: String) {
        emailLabel.text = email
        
        // Get initials from username
        let initials = username.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
        initialsLabel.text = initials.uppercased()
        
        // Use username as nickname
        nicknameLabel.text = "@\(username.lowercased().replacingOccurrences(of: " ", with: ""))"
    }
}
