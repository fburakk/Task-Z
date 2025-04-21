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
    private var tasks: [Int: [Task]] = [:] // statusId -> [Task]
    weak var delegate: BoardDetailViewControllerDelegate?
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    private let addTaskButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.25
        
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let image = UIImage(systemName: "plus", withConfiguration: config)
        button.setImage(image, for: .normal)
        
        return button
    }()
    
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
        setupCollectionView()
        setupNavigationBar()
        setupAddTaskButton()
        loadData()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: board.background)
        
        view.addSubview(collectionView)
        view.addSubview(addTaskButton)
        view.addSubview(loadingIndicator)
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            addTaskButton.widthAnchor.constraint(equalToConstant: 56),
            addTaskButton.heightAnchor.constraint(equalToConstant: 56),
            addTaskButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            addTaskButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        addTaskButton.addTarget(self, action: #selector(addTaskButtonTapped), for: .touchUpInside)
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(StatusColumnCell.self, forCellWithReuseIdentifier: StatusColumnCell.identifier)
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
    
    private func setupAddTaskButton() {
        // Implementation of setupAddTaskButton method
    }
    
    private func loadData() {
        loadingIndicator.startAnimating()
        
        let group = DispatchGroup()
        var loadedStatuses: [BoardStatus]?
        var loadedUsers: [BoardUser]?
        var loadedTasks: [Task]?
        var errors: [Error] = []
        
        // Load statuses
        group.enter()
        APIService.shared.getBoardStatuses(boardId: board.id) { result in
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
        APIService.shared.getBoardUsers(boardId: board.id) { result in
            defer { group.leave() }
            switch result {
            case .success(let users):
                loadedUsers = users
            case .failure(let error):
                errors.append(error)
            }
        }
        
        // Load tasks
        group.enter()
        APIService.shared.getBoardTasks(boardId: board.id) { result in
            defer { group.leave() }
            switch result {
            case .success(let tasks):
                loadedTasks = tasks
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
            
            if let statuses = loadedStatuses,
               let users = loadedUsers,
               let tasks = loadedTasks {
                self.statuses = statuses
                self.users = users
                
                // Group tasks by status
                self.tasks = Dictionary(grouping: tasks, by: { $0.statusId })
                self.collectionView.reloadData()
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
    
    @objc private func addTaskButtonTapped() {
        let alert = UIAlertController(title: "Yeni Görev", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Görev Başlığı"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Açıklama"
        }
        
        let priorities = ["Düşük", "Orta", "Yüksek"]
        alert.addTextField { textField in
            textField.placeholder = "Öncelik"
            
            let pickerView = UIPickerView()
            pickerView.delegate = self
            pickerView.dataSource = self
            textField.inputView = pickerView
            textField.text = priorities[1] // Default to medium priority
        }
        
        let createAction = UIAlertAction(title: "Oluştur", style: .default) { [weak self] _ in
            guard let self = self,
                  let title = alert.textFields?[0].text,
                  let description = alert.textFields?[1].text,
                  !title.isEmpty else { return }
            
            let priorityText = alert.textFields?[2].text ?? priorities[1]
            let priority: TaskPriority
            switch priorityText {
            case "Düşük":
                priority = .low
            case "Yüksek":
                priority = .high
            default:
                priority = .medium
            }
            
            self.loadingIndicator.startAnimating()
            APIService.shared.createTask(
                boardId: self.board.id,
                title: title,
                description: description,
                priority: priority.rawValue,
                dueDate: nil,
                assigneeId: nil
            ) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    
                    switch result {
                    case .success(let task):
                        // Add the new task to the first status
                        if let firstStatus = self.statuses.first {
                            var statusTasks = self.tasks[firstStatus.id] ?? []
                            statusTasks.append(task)
                            self.tasks[firstStatus.id] = statusTasks
                            self.collectionView.reloadData()
                        }
                    case .failure(let error):
                        self.showError(error)
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "İptal", style: .cancel)
        
        alert.addAction(createAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate
extension BoardDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return statuses.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StatusColumnCell.identifier, for: indexPath) as? StatusColumnCell else {
            return UICollectionViewCell()
        }
        
        let status = statuses[indexPath.item]
        let statusTasks = tasks[status.id] ?? []
        cell.configure(with: status, tasks: statusTasks)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.bounds.width * 0.85
        let height = collectionView.bounds.height
        return CGSize(width: width, height: height)
    }
}

// MARK: - UIPickerViewDelegate & UIPickerViewDataSource
extension BoardDetailViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 3 // Low, Medium, High
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch row {
        case 0: return "Düşük"
        case 1: return "Orta"
        case 2: return "Yüksek"
        default: return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let priorities = ["Düşük", "Orta", "Yüksek"]
        if let textField = pickerView.superview?.superview as? UITextField {
            textField.text = priorities[row]
            textField.resignFirstResponder()
        }
    }
}
