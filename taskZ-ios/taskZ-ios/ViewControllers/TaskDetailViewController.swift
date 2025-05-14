//
//  TaskDetailViewController.swift
//  taskZ-ios
//
//  Created by Burak Köse on 23.03.2025.
//

import UIKit

protocol TaskDetailViewControllerDelegate: AnyObject {
    func taskDetailViewController(_ viewController: TaskDetailViewController, didUpdateTask task: Task)
    func memberSelectionViewController(_ viewController: MemberSelectionViewController, didSelectUsername username: String?)
    func didDeleteTask()
}

// MARK: - MemberSelectionViewControllerDelegate
protocol MemberSelectionViewControllerDelegate: AnyObject {
    func memberSelectionViewController(_ viewController: MemberSelectionViewController, didSelectUsername username: String?)
}

class TaskDetailViewController: UIViewController {
    private var task: Task
    private let board: Board
    private var statuses: [BoardStatus] = []
    private var boardUsers: [BoardUser] = []
    weak var delegate: TaskDetailViewControllerDelegate?
    
    // Add properties to track changes
    private var updatedTitle: String?
    private var updatedDescription: String?
    private var updatedDueDate: Date?
    private var updatedUsername: String?
    private var updatedStatusId: Int?
    private var hasChanges: Bool = false
    var onDelete: (() -> Void)?
    
    enum Section: Int, CaseIterable {
        case header
        case project
        case description
        case dates
        case members
        case status
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .black
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    init(task: Task, board: Board) {
        self.task = task
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
        registerCells()
        loadStatuses()
        loadBoardUsers()
    }
    
    private func loadStatuses() {
        APIService.shared.getBoardStatuses(boardId: board.id) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let statuses):
                self.statuses = statuses
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            case .failure(let error):
                print("Failed to load statuses: \(error)")
            }
        }
    }
    
    private func loadBoardUsers() {
        APIService.shared.getBoardUsers(boardId: board.id) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let users):
                self.boardUsers = users
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            case .failure(let error):
                print("Failed to load board users: \(error)")
            }
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
        
        // Close button (left)
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )
        closeButton.tintColor = .white
        navigationItem.leftBarButtonItem = closeButton
        
        // Save and Menu buttons (right)
        let saveButton = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveButtonTapped)
        )
        saveButton.tintColor = .white
        
        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: self,
            action: #selector(menuButtonTapped)
        )
        menuButton.tintColor = .white
        
        navigationItem.rightBarButtonItems = [saveButton, menuButton]
    }
    
    private func registerCells() {
        // Register header cell
        collectionView.register(TaskHeaderCell.self, forCellWithReuseIdentifier: TaskHeaderCell.identifier)
        
        // Register project cell
        collectionView.register(ProjectCell.self, forCellWithReuseIdentifier: ProjectCell.identifier)
        
        // Register description cell
        collectionView.register(DescriptionCell.self, forCellWithReuseIdentifier: DescriptionCell.identifier)
        
        // Register date cell
        collectionView.register(DateCell.self, forCellWithReuseIdentifier: DateCell.identifier)
        
        // Register member cell
        collectionView.register(MemberCell.self, forCellWithReuseIdentifier: MemberCell.identifier)
        
        // Register status cell
        collectionView.register(StatusCell.self, forCellWithReuseIdentifier: StatusCell.identifier)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self = self,
                  let section = Section(rawValue: sectionIndex) else {
                return nil
            }
            
            switch section {
            case .header:
                return self.createHeaderSection()
            case .project:
                return self.createProjectSection()
            case .description:
                return self.createDescriptionSection()
            case .dates:
                return self.createDatesSection()
            case .members:
                return self.createMembersSection()
            case .status:
                return self.createStatusSection()
            }
        }
        return layout
    }
    
    private func createHeaderSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                            heightDimension: .estimated(60))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                             heightDimension: .estimated(60))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16)
        return section
    }
    
    private func createProjectSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                            heightDimension: .estimated(64))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                             heightDimension: .estimated(64))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16)
        return section
    }
    
    private func createDescriptionSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                            heightDimension: .estimated(44))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                             heightDimension: .estimated(44))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        return section
    }
    
    private func createDatesSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                            heightDimension: .estimated(44))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                             heightDimension: .estimated(44))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        return section
    }
    
    private func createMembersSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                            heightDimension: .estimated(44))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                             heightDimension: .estimated(44))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        return section
    }
    
    private func createStatusSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                            heightDimension: .estimated(44))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                             heightDimension: .estimated(44))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
        return section
    }
    
    @objc private func closeButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func saveButtonTapped() {
        guard hasChanges else { return }
        
        updateTask(
            title: updatedTitle,
            description: updatedDescription,
            dueDate: updatedDueDate.map { ISO8601DateFormatter().string(from: $0) },
            username: updatedUsername,
            statusId: updatedStatusId
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedTask):
                    self?.delegate?.taskDetailViewController(self!, didUpdateTask: updatedTask)
                    self?.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to update task: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
    
    @objc private func menuButtonTapped() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete Task", style: .destructive) { [weak self] _ in
            self?.showDeleteConfirmation()
        }
        actionSheet.addAction(deleteAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheet.addAction(cancelAction)
        
        // For iPad support
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        
        present(actionSheet, animated: true)
    }
    
    private func showDeleteConfirmation() {
        let alert = UIAlertController(title: "Delete Task", message: "Are you sure you want to delete this task? This action cannot be undone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            APIService.shared.deleteTask(id: self.task.id) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.delegate?.didDeleteTask()
                        self.navigationController?.popViewController(animated: true)
                    case .failure(let error):
                        let errorAlert = UIAlertController(title: "Error", message: "Failed to delete task: \(error.localizedDescription)", preferredStyle: .alert)
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(errorAlert, animated: true)
                    }
                }
            }
        })
        present(alert, animated: true)
    }
    
    private func updateTask(title: String? = nil,
                          description: String? = nil,
                          priority: String? = nil,
                          dueDate: String? = nil,
                          username: String? = nil,
                          statusId: Int? = nil,
                          position: Int? = nil,
                          completion: @escaping (Result<Task, Error>) -> Void) {
        
        APIService.shared.updateTask(
            id: task.id,
            title: title,
            description: description,
            priority: priority,
            dueDate: dueDate,
            username: username,
            statusId: statusId,
            position: position
        ) { [weak self] result in
            switch result {
            case .success(let updatedTask):
                self?.task = updatedTask
                completion(.success(updatedTask))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func updateTaskStatus(to status: BoardStatus) {
        updatedStatusId = status.id
        hasChanges = true
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource
extension TaskDetailViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Section.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        
        switch section {
        case .header, .project, .description, .members, .status, .dates:
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return UICollectionViewCell()
        }
        
        switch section {
        case .header:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TaskHeaderCell.identifier, for: indexPath) as! TaskHeaderCell
            cell.configure(with: task)
            cell.delegate = self
            return cell
            
        case .project:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProjectCell.identifier, for: indexPath) as! ProjectCell
            cell.configure(projectName: board.name, teamName: board.name, color: UIColor(hex: board.background) ?? .systemBlue)
            return cell
            
        case .description:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DescriptionCell.identifier, for: indexPath) as! DescriptionCell
            cell.configure(description: task.description)
            cell.delegate = self
            return cell
            
        case .dates:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DateCell.identifier, for: indexPath) as! DateCell
           
               
            cell.configure(title: "Bitiş tarihi", date: task.dueDate)
            
            cell.delegate = self
            return cell
            
        case .members:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MemberCell.identifier, for: indexPath) as! MemberCell
            cell.configure(username: updatedUsername ?? task.assigneeUsername)
            cell.delegate = self
            return cell
            
        case .status:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StatusCell.identifier, for: indexPath) as! StatusCell
            if let statusId = updatedStatusId,
               let currentStatus = statuses.first(where: { $0.id == statusId }) {
                cell.configure(with: currentStatus)
            } else if let currentStatus = statuses.first(where: { $0.id == task.statusId }) {
                cell.configure(with: currentStatus)
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate
extension TaskDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }
        
        switch section {
        case .status:
            showStatusSelectionMenu()
        default:
            break
        }
    }
    
    private func showStatusSelectionMenu() {
        let alert = UIAlertController(title: "Select Status", message: nil, preferredStyle: .actionSheet)
        
        for status in statuses {
            let action = UIAlertAction(title: status.title, style: .default) { [weak self] _ in
                self?.updateTaskStatus(to: status)
            }
            alert.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
}

// MARK: - Cell Delegates
extension TaskDetailViewController: TaskHeaderCellDelegate, DescriptionCellDelegate, DateCellDelegate, MemberCellDelegate {
    func taskHeaderCell(_ cell: TaskHeaderCell, didUpdateTitle title: String) {
        updatedTitle = title
        hasChanges = true
    }
    
    func descriptionCell(_ cell: DescriptionCell, didUpdateDescription description: String) {
        updatedDescription = description
        hasChanges = true
    }
    
    func dateCell(_ cell: DateCell, didUpdateDate date: Date?) {
        if let indexPath = collectionView.indexPath(for: cell) {
            updatedDueDate = date
            hasChanges = true
        }
    }
    
    func memberCell(_ cell: MemberCell, didUpdateUsername username: String) {
        updatedUsername = username
        hasChanges = true
    }
    
    func memberCellDidTap(_ cell: MemberCell) {
        showMemberSelectionMenu()
    }
    
    private func showMemberSelectionMenu() {
        let memberSelectionVC = MemberSelectionViewController(
            users: boardUsers,
            selectedUsername: updatedUsername ?? task.assigneeUsername
        ) { [weak self] selectedUsername in
            guard let self = self else { return }
            // API'ye güncelleme isteği gönder
            self.updateTask(
                title: self.updatedTitle ?? self.task.title,
                description: self.updatedDescription ?? self.task.description,
                dueDate: self.updatedDueDate.map { ISO8601DateFormatter().string(from: $0) } ?? self.task.dueDate.map { ISO8601DateFormatter().string(from: $0) },
                username: selectedUsername,
                statusId: self.updatedStatusId ?? self.task.statusId
            ) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let updatedTask):
                        self.updatedUsername = selectedUsername
                        self.hasChanges = true
                        self.task = updatedTask
                        self.collectionView.reloadData()
                    case .failure(let error):
                        let alert = UIAlertController(title: "Error", message: "Failed to update member: \(error.localizedDescription)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }
        memberSelectionVC.delegate = self
        present(memberSelectionVC, animated: true)
    }
}

// MARK: - MemberSelectionViewController
class MemberSelectionViewController: UIViewController {
    weak var delegate: MemberSelectionViewControllerDelegate?
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Select Member"
        label.textColor = .white
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        return tableView
    }()
    
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        return stackView
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(white: 0.3, alpha: 1.0)
        button.layer.cornerRadius = 8
        return button
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        return button
    }()
    
    private var users: [BoardUser]
    private var selectedUsername: String?
    private var onSave: ((String?) -> Void)?
    
    init(users: [BoardUser], selectedUsername: String?, onSave: @escaping (String?) -> Void) {
        self.users = users
        self.selectedUsername = selectedUsername
        self.onSave = onSave
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(tableView)
        containerView.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(saveButton)

        // Register cell and set delegate/dataSource
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UserCell")
        tableView.delegate = self
        tableView.dataSource = self

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -16),
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44)
        ])

        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveButtonTapped() {
        onSave?(selectedUsername)
        dismiss(animated: true)
    }
}

extension MemberSelectionViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        let user = users[indexPath.row]
        cell.textLabel?.text = user.username

        // Plus/minus button
        let button = UIButton(type: .system)
        let isSelected = selectedUsername == user.username
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        let image = UIImage(systemName: isSelected ? "minus.circle.fill" : "plus.circle.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = isSelected ? .systemRed : .systemBlue
        button.tag = indexPath.row
        button.addTarget(self, action: #selector(memberButtonTapped(_:)), for: .touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        cell.accessoryView = button

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
    
    @objc private func memberButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        let user = users[index]
        if selectedUsername == user.username {
            selectedUsername = nil
        } else {
            selectedUsername = user.username
        }
        tableView.reloadData()
        delegate?.memberSelectionViewController(self, didSelectUsername: selectedUsername)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let label = UILabel()
        label.text = "Select Member"
        label.textColor = .white
        label.font = .systemFont(ofSize: 15, weight: .medium)
        
        headerView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
}

extension TaskDetailViewController: MemberSelectionViewControllerDelegate {
    func memberSelectionViewController(_ viewController: MemberSelectionViewController, didSelectUsername username: String?) {
        self.updatedUsername = username
        self.hasChanges = true
        self.collectionView.reloadData()
    }
}
