//
//  BoardDetailViewController.swift
//  taskZ-ios
//
//  Created by Burak Köse on 23.03.2025.
//

import UIKit

class BoardDetailViewController: UIViewController {
    private let board: Board
    private var statuses: [BoardStatus] = []
    private var users: [BoardUser] = []
    
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
        Task {
            do {
                loadingIndicator.startAnimating()
                
                async let statusesResult = APIService.shared.getBoardStatuses(boardId: board.id)
                async let usersResult = APIService.shared.getBoardUsers(boardId: board.id)
                
                let (statuses, users) = try await (statusesResult, usersResult)
                self.statuses = statuses
                self.users = users
                
                loadingIndicator.stopAnimating()
                // Setup your board view with statuses here
                
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
        
        // Archive/Unarchive
        let archiveTitle = board.isArchived ? "Arşivden Çıkar" : "Arşivle"
        alertController.addAction(UIAlertAction(title: archiveTitle, style: .default) { [weak self] _ in
            self?.toggleArchive()
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
        let alert = UIAlertController(title: "Yeni Durum", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Durum Adı"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Renk (örn: #FF0000)"
            textField.text = "#007AFF"
        }
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Ekle", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let title = alert?.textFields?[0].text,
                  let color = alert?.textFields?[1].text,
                  !title.isEmpty else { return }
            
            Task {
                do {
                    let newStatus = try await APIService.shared.createBoardStatus(
                        boardId: self.board.id,
                        title: title,
                        color: color
                    )
                    self.statuses.append(newStatus)
                    // Update your board view
                } catch {
                    self.showError(error)
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showAddUserDialog() {
        let alert = UIAlertController(title: "Kullanıcı Ekle", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Kullanıcı Adı"
        }
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Ekle", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let username = alert?.textFields?[0].text,
                  !username.isEmpty else { return }
            
            Task {
                do {
                    let newUser = try await APIService.shared.addUserToBoard(
                        boardId: self.board.id,
                        username: username,
                        role: "member"  // Default role
                    )
                    self.users.append(newUser)
                } catch {
                    self.showError(error)
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showEditBoardDialog() {
        let alert = UIAlertController(title: "Pano Düzenle", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Pano Adı"
            textField.text = self.board.name
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Arkaplan Rengi (örn: #FF0000)"
            textField.text = self.board.background
        }
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Kaydet", style: .default) { [weak self, weak alert] _ in
            guard let self = self else { return }
            
            let name = alert?.textFields?[0].text
            let background = alert?.textFields?[1].text
            
            Task {
                do {
                    let updatedBoard = try await APIService.shared.updateBoard(
                        id: self.board.id,
                        name: name,
                        background: background
                    )
                    // Update UI with new board details
                    self.title = updatedBoard.name
                    self.view.backgroundColor = UIColor(hex: updatedBoard.background)
                } catch {
                    self.showError(error)
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func toggleArchive() {
        Task {
            do {
                let updatedBoard = try await APIService.shared.toggleBoardArchive(
                    id: board.id,
                    archived: !board.isArchived
                )
                // Update UI or navigate back if needed
                if updatedBoard.isArchived {
                    navigationController?.popViewController(animated: true)
                }
            } catch {
                showError(error)
            }
        }
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
            
            Task {
                do {
                    try await APIService.shared.deleteBoard(id: self.board.id)
                    self.navigationController?.popViewController(animated: true)
                } catch {
                    self.showError(error)
                }
            }
        })
        
        present(alert, animated: true)
    }
}
