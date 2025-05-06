//
//  TaskDetailViewController.swift
//  taskZ-ios
//
//  Created by Burak Köse on 23.03.2025.
//

import UIKit

protocol TaskDetailViewControllerDelegate: AnyObject {
    func taskDetailViewController(_ viewController: TaskDetailViewController, didUpdateTask task: Task)
}

class TaskDetailViewController: UIViewController {
    private var task: Task
    private let board: Board
    private var statuses: [BoardStatus] = []
    weak var delegate: TaskDetailViewControllerDelegate?
    
    // Add properties to track changes
    private var updatedTitle: String?
    private var updatedDescription: String?
    private var updatedDueDate: Date?
    private var updatedUsername: String?
    private var updatedStatusId: Int?
    private var hasChanges: Bool = false
    
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
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )
        closeButton.tintColor = .white
        navigationItem.leftBarButtonItem = closeButton
        
        let saveButton = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveButtonTapped)
        )
        saveButton.tintColor = .white
        
        navigationItem.rightBarButtonItem = saveButton
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
        updateTask(
            title: task.title,
            description: task.description,
            priority: task.priority?.rawValue,
            dueDate: task.dueDate.map { ISO8601DateFormatter().string(from: $0) },
            username: task.assigneeUsername,
            statusId: status.id,
            position: task.position) { result in
                switch result {
                case .success(let success):
                    self.navigationController?.popViewController(animated: true)
                case .failure(let failure):
                    print(failure.localizedDescription)
                }
            }
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
        case .header, .project, .description, .members, .status:
            return 1
        case .dates:
            return 2 // Start date and end date
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
            if indexPath.item == 0 {
                cell.configure(title: "Başlangıç tarihi", date: task.dueDate)
            } else {
                cell.configure(title: "Bitiş tarihi", date: task.dueDate)
            }
            cell.delegate = self
            return cell
            
        case .members:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MemberCell.identifier, for: indexPath) as! MemberCell
            cell.configure(username: task.assigneeUsername)
            cell.delegate = self
            return cell
            
        case .status:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StatusCell.identifier, for: indexPath) as! StatusCell
            if let currentStatus = statuses.first(where: { $0.id == task.statusId }) {
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
            if indexPath.item == 1 { // Due date cell
                updatedDueDate = date
                hasChanges = true
            }
        }
    }
    
    func memberCell(_ cell: MemberCell, didUpdateUsername username: String) {
        updatedUsername = username
        hasChanges = true
    }
}
