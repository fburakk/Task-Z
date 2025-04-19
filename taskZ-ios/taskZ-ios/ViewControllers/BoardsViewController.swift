//
//  BoardsViewController.swift
//  taskZ-ios
//
//  Created by Burak Köse on 22.03.2025.
//

import UIKit

class BoardCell: UITableViewCell {
    private let squareView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 6
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        squareView.backgroundColor = nil
        titleLabel.text = nil
    }
    
    private func setupUI() {
        backgroundColor = .secondarySystemGroupedBackground
        
        contentView.addSubview(squareView)
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            squareView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            squareView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            squareView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),
            squareView.widthAnchor.constraint(equalToConstant: 32),
            squareView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: squareView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with title: String, color: UIColor) {
        titleLabel.text = title
        squareView.backgroundColor = color
    }
}

class BoardsViewController: UIViewController {
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.backgroundColor = .clear
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(BoardCell.self, forCellReuseIdentifier: "BoardCell")
        return table
    }()
    
    private let searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchBar.placeholder = "Panolar"
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.tintColor = .white
        return controller
    }()
    
    private var workspaces: [Workspace] = []
    private var boards: [String: [Board]] = [:] // Workspace ID -> Boards
    private var filteredBoards: [String: [Board]] = [:]
    private var isSearching: Bool = false
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupTabBar()
        setupNavigationBar()
        setupSearchController()
        setupNavigationBarButtons()
        setupLoadingIndicator()
        loadData()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        navigationItem.hidesBackButton = true
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.title = "TaskZ"
        
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = .black
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            
            navigationController?.navigationBar.standardAppearance = navBarAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        }
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Panolar"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        searchController.searchBar.searchTextField.backgroundColor = .systemGroupedBackground
        searchController.searchBar.tintColor = .white
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupTabBar() {
        tabBarItem = UITabBarItem(title: "Panolar", image: UIImage(systemName: "mail.stack"), tag: 0)
    }
    
    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func loadData() {
        Task {
            do {
                loadingIndicator.startAnimating()
                workspaces = try await APIService.shared.getAllWorkspaces()
                
                for workspace in workspaces {
                    let workspaceBoards = try await APIService.shared.getBoardsInWorkspace(workspaceId: workspace.id)
                    boards[workspace.id] = workspaceBoards
                }
                
                loadingIndicator.stopAnimating()
                tableView.reloadData()
            } catch {
                loadingIndicator.stopAnimating()
                showError(error)
            }
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Hata",
            message: "Veriler yüklenirken bir hata oluştu: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
    
    private func filterBoards(for searchText: String) {
        filteredBoards.removeAll()
        
        for (workspaceId, workspaceBoards) in boards {
            let filtered = workspaceBoards.filter { board in
                board.name.lowercased().contains(searchText.lowercased())
            }
            if !filtered.isEmpty {
                filteredBoards[workspaceId] = filtered
            }
        }
        
        tableView.reloadData()
    }
    
    private func setupNavigationBarButtons() {
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addButtonTapped)
        )
        addButton.tintColor = .tintColor
        navigationItem.rightBarButtonItem = addButton
    }
    
    @objc private func addButtonTapped() {
        let createBoardVC = CreateBoardViewController()
        createBoardVC.delegate = self
        let navController = UINavigationController(rootViewController: createBoardVC)
        present(navController, animated: true)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension BoardsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return workspaces.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let workspace = workspaces[section]
        return isSearching ? 
            (filteredBoards[workspace.id]?.count ?? 0) : 
            (boards[workspace.id]?.count ?? 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BoardCell", for: indexPath) as? BoardCell else {
            return UITableViewCell()
        }
        
        let workspace = workspaces[indexPath.section]
        let boardsArray = isSearching ? filteredBoards[workspace.id] : boards[workspace.id]
        
        if let board = boardsArray?[indexPath.row] {
            cell.configure(with: board.name, color: UIColor(hex: board.background) ?? .blue)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return workspaces[section].name.uppercased()
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = .white
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let workspace = workspaces[indexPath.section]
        let boardsArray = isSearching ? filteredBoards[workspace.id] : boards[workspace.id]
        
        if let board = boardsArray?[indexPath.row] {
            // Navigate to board detail view controller
            let boardDetailVC = BoardDetailViewController(board: board)
            navigationController?.pushViewController(boardDetailVC, animated: true)
        }
    }
}

// MARK: - UISearchResultsUpdating & UISearchBarDelegate
extension BoardsViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            isSearching = false
            tableView.reloadData()
            return
        }
        
        isSearching = true
        filterBoards(for: searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
        tableView.reloadData()
    }
}

// MARK: - CreateBoardViewControllerDelegate
extension BoardsViewController: CreateBoardViewControllerDelegate {
    func didCreateBoard() {
        loadData() // Reload all data when a new board is created
    }
}
