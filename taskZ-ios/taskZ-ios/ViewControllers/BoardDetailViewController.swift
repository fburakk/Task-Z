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
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = .zero
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.decelerationRate = .fast
        collectionView.contentInsetAdjustmentBehavior = .never
        return collectionView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        return indicator
    }()
    
    private let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.pageIndicatorTintColor = .gray
        pageControl.backgroundColor = .clear
        return pageControl
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
        view.backgroundColor = UIColor.black
        
        view.addSubview(collectionView)
        view.addSubview(loadingIndicator)
        view.addSubview(pageControl)
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            pageControl.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(StatusColumnCell.self, forCellWithReuseIdentifier: StatusColumnCell.identifier)
        collectionView.register(AddStatusCell.self, forCellWithReuseIdentifier: AddStatusCell.identifier)
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
                
                // Update page control
                self.pageControl.numberOfPages = statuses.count + 1 // +1 for Add Status
                self.pageControl.currentPage = 0
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
                        self.tasks[status.id] = []
                        self.pageControl.numberOfPages = self.statuses.count + 1
                        self.collectionView.reloadData()
                        
                        // Scroll to the newly added status after a brief delay to ensure layout is updated
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            let indexPath = IndexPath(item: self.statuses.count - 1, section: 0)
                            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                        }
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
        guard let firstStatus = statuses.first else {
            showError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No status columns available"]))
            return
        }
        showAddTaskDialog(for: firstStatus)
    }
    
    private func showAddTaskDialog(for status: BoardStatus) {
        let alert = UIAlertController(title: "New Task in \(status.title)", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Task Title"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Description"
        }
        
        let priorities = ["Low", "Medium", "High"]
        alert.addTextField { textField in
            textField.placeholder = "Priority"
            
            let pickerView = UIPickerView()
            pickerView.delegate = self
            pickerView.dataSource = self
            textField.inputView = pickerView
            textField.text = priorities[1] // Default to medium priority
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Due Date (Optional)"
            
            let datePicker = UIDatePicker()
            datePicker.datePickerMode = .dateAndTime
            datePicker.preferredDatePickerStyle = .wheels
            datePicker.minimumDate = Date()
            textField.inputView = datePicker
            
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.datePickerDone))
            toolbar.setItems([doneButton], animated: false)
            textField.inputAccessoryView = toolbar
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let title = alert?.textFields?[0].text,
                  let description = alert?.textFields?[1].text,
                  !title.isEmpty else { return }
            
            let priorityText = alert?.textFields?[2].text?.lowercased() ?? "medium"
            let priority: TaskPriority = TaskPriority(rawValue: priorityText) ?? .medium
            
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime]
            
            var dueDate: String?
            if let dateField = alert?.textFields?[3],
               let datePicker = dateField.inputView as? UIDatePicker {
                dueDate = dateFormatter.string(from: datePicker.date)
            }
            
            let taskRequest = Task.CreateRequest(
                title: title,
                description: description,
                priority: priority,
                dueDate: dateFormatter.date(from: dueDate ?? ""),
                assigneeId: nil,
                statusId: status.id
            )
            
            self.loadingIndicator.startAnimating()
            APIService.shared.createTask(
                boardId: self.board.id,
                title: taskRequest.title,
                description: taskRequest.description,
                priority: taskRequest.priority.rawValue,
                dueDate: dueDate,
                assigneeId: taskRequest.assigneeId,
                statusId: taskRequest.statusId
            ) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    
                    switch result {
                    case .success(let task):
                        var statusTasks = self.tasks[status.id] ?? []
                        statusTasks.append(task)
                        self.tasks[status.id] = statusTasks
                        self.collectionView.reloadData()
                    case .failure(let error):
                        self.showError(error)
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(createAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    @objc private func datePickerDone(_ sender: UIBarButtonItem) {
        view.endEditing(true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = round(scrollView.contentOffset.x / scrollView.bounds.width)
        pageControl.currentPage = Int(page)
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate
extension BoardDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return statuses.count + 1  // +1 for Add Status cell
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == statuses.count {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddStatusCell.identifier, for: indexPath) as? AddStatusCell else {
                return UICollectionViewCell()
            }
            
            cell.configure { [weak self] in
                self?.showAddStatusDialog()
            }
            
            return cell
        }
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StatusColumnCell.identifier, for: indexPath) as? StatusColumnCell else {
            return UICollectionViewCell()
        }
        
        let status = statuses[indexPath.item]
        let statusTasks = tasks[status.id] ?? []
        cell.configure(with: status, tasks: statusTasks)
        cell.onAddTask = { [weak self] status in
            self?.showAddTaskDialog(for: status)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
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
        case 0: return "Low"
        case 1: return "Medium"
        case 2: return "High"
        default: return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let priorities = ["Low", "Medium", "High"]
        if let textField = pickerView.superview?.superview as? UITextField {
            textField.text = priorities[row]
            textField.resignFirstResponder()
        }
    }
}

class AddStatusCell: UICollectionViewCell {
    static let identifier = "AddStatusCell"
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 8
        button.setTitle("Add Status", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            addButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            addButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    func configure(action: @escaping () -> Void) {
        addButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        self.action = action
    }
    
    private var action: (() -> Void)?
    
    @objc private func buttonTapped() {
        action?()
    }
}
