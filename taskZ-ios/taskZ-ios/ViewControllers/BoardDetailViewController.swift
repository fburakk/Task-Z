//
//  BoardDetailViewController.swift
//  taskZ-ios
//
//  Created by Burak Köse on 23.03.2025.
//

import UIKit

protocol BoardDetailViewControllerDelegate: AnyObject {
    func boardDetailViewController(_ viewController: BoardDetailViewController, didDeleteBoard board: Board)
    func boardDetailViewController(_ viewController: BoardDetailViewController, didUpdateBoard board: Board)
}

class BoardDetailViewController: UIViewController {
    private var board: Board
    private var statuses: [BoardStatus] = []
    private var users: [BoardUser] = []
    weak var delegate: BoardDetailViewControllerDelegate?
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        return indicator
    }()
    
    init(board: Board) {
        self.board = board
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadData()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: board.background)
        
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        title = board.name
        navigationItem.largeTitleDisplayMode = .never
        
        let moreButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: self,
            action: #selector(moreButtonTapped)
        )
        navigationItem.rightBarButtonItem = moreButton
    }
    
    private func loadData() {
        loadingIndicator.startAnimating()
        
        let group = DispatchGroup()
        var loadedStatuses: [BoardStatus]?
        var loadedUsers: [BoardUser]?
        var errors: [Error] = []
        
        // Load statuses
        group.enter()
        APIService.shared.getBoardStatuses(boardId: board.id) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let statuses):
                loadedStatuses = statuses
            case .failure(let error):
                errors.append(error)
            }
        }
        
        // Load users
        group.enter()
        APIService.shared.getBoardUsers(boardId: board.id) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let users):
                loadedUsers = users
            case .failure(let error):
                errors.append(error)
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.loadingIndicator.stopAnimating()
            
            if let error = errors.first {
                self.showError(error)
                return
            }
            
            if let statuses = loadedStatuses, let users = loadedUsers {
                self.statuses = statuses
                self.users = users
                // Setup your board view with statuses here
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
    
    @objc private func moreButtonTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Add Status
        alertController.addAction(UIAlertAction(title: "Durum Ekle", style: .default) { [weak self] _ in
            self?.showAddStatusDialog()
        })
        
        // Add User
        alertController.addAction(UIAlertAction(title: "Kullanıcı Ekle", style: .default) { [weak self] _ in
            self?.showAddUserDialog()
        })
        
        // Edit Board
        alertController.addAction(UIAlertAction(title: "Düzenle", style: .default) { [weak self] _ in
            self?.showEditBoardDialog()
        })
        
        // Delete Board
        alertController.addAction(UIAlertAction(title: "Sil", style: .destructive) { [weak self] _ in
            self?.showDeleteConfirmation()
        })
        
        alertController.addAction(UIAlertAction(title: "İptal", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    private func showAddStatusDialog() {
        let alert = UIAlertController(title: "Add Status", message: "Enter a title for the new status", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Status Title"
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let title = alert.textFields?.first?.text,
                  !title.isEmpty else { return }
            
            self.loadingIndicator.startAnimating()
            APIService.shared.createBoardStatus(boardId: self.board.id, title: title) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    
                    switch result {
                    case .success(let status):
                        self.statuses.append(status)
                        // Update your board view
                    case .failure(let error):
                        self.showError(error)
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func showAddUserDialog() {
        let alert = UIAlertController(title: "Add User", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Username"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let username = alert?.textFields?[0].text,
                  !username.isEmpty else { return }
            
            self.loadingIndicator.startAnimating()
            APIService.shared.addUserToBoard(
                boardId: self.board.id,
                username: username  // role will default to "viewer"
            ) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    
                    switch result {
                    case .success(let newUser):
                        self.users.append(newUser)
                        // Update UI if needed
                    case .failure(let error):
                        self.showError(error)
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showEditBoardDialog() {
        let alert = UIAlertController(title: "Edit Board", message: "Both name and background color are required", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Board Name (required)"
            textField.text = self.board.name
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Background Color (e.g. #FF0000, required)"
            textField.text = self.board.background
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let name = alert?.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let background = alert?.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty,
                  !background.isEmpty else {
                self?.showError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Name and background color are required"]))
                return
            }
            
            self.loadingIndicator.startAnimating()
            APIService.shared.updateBoard(
                id: self.board.id,
                name: name,
                background: background
            ) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    
                    switch result {
                    case .success:
                        // Update local board data since API returns 204
                        self.board.name = name
                        self.title = name
                        self.board.background = background
                        self.view.backgroundColor = UIColor(hex: background)
                        // Notify delegate about the update
                        self.delegate?.boardDetailViewController(self, didUpdateBoard: self.board)
                    case .failure(let error):
                        self.showError(error)
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showDeleteConfirmation() {
        let alert = UIAlertController(
            title: "Pano Sil",
            message: "Bu panoyu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sil", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            self.loadingIndicator.startAnimating()
            APIService.shared.deleteBoard(id: self.board.id) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    
                    switch result {
                    case .success:
                        self.delegate?.boardDetailViewController(self, didDeleteBoard: self.board)
                        self.navigationController?.popViewController(animated: true)
                    case .failure(let error):
                        self.showError(error)
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    func showEditStatusAlert(for status: BoardStatus) {
        let alert = UIAlertController(title: "Edit Status", message: "Enter a new title for the status", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = status.title
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let newTitle = alert.textFields?.first?.text,
                  !newTitle.isEmpty else { return }
            
            APIService.shared.updateBoardStatus(boardId: self.board.id, statusId: status.id, title: newTitle) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(let updatedStatus):
                        if let index = self.statuses.firstIndex(where: { $0.id == status.id }) {
                            self.statuses[index] = updatedStatus
                        }
                    case .failure(let error):
                        self.showError(error)
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
}
