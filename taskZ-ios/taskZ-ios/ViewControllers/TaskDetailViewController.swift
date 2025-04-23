//
//  TaskDetailViewController.swift
//  taskZ-ios
//
//  Created by Burak Köse on 23.03.2025.
//

import UIKit

class TaskDetailViewController: UIViewController {
    private var task: Task
    private let board: Board
    private var statuses: [BoardStatus] = []
    
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
        
        let moreButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: self,
            action: #selector(moreButtonTapped)
        )
        moreButton.tintColor = .white
        
        let updateButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.pencil"),
            style: .plain,
            target: self,
            action: #selector(updateButtonTapped)
        )
        updateButton.tintColor = .white
        
        navigationItem.rightBarButtonItems = [moreButton, updateButton]
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
    
    @objc private func moreButtonTapped() {
        // Show more options menu
    }
    
    @objc private func updateButtonTapped() {
        // Show update options menu
        let alert = UIAlertController(title: "Update Task", message: nil, preferredStyle: .actionSheet)
        
        let updateTitleAction = UIAlertAction(title: "Update Title", style: .default) { [weak self] _ in
            self?.showUpdateTitleAlert()
        }
        
        let updateDescriptionAction = UIAlertAction(title: "Update Description", style: .default) { [weak self] _ in
            self?.showUpdateDescriptionAlert()
        }
        
        let updatePriorityAction = UIAlertAction(title: "Update Priority", style: .default) { [weak self] _ in
            self?.showUpdatePriorityAlert()
        }
        
        let updateDueDateAction = UIAlertAction(title: "Update Due Date", style: .default) { [weak self] _ in
            self?.showUpdateDueDateAlert()
        }
        
        let updateAssigneeAction = UIAlertAction(title: "Update Assignee", style: .default) { [weak self] _ in
            self?.showUpdateAssigneeAlert()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(updateTitleAction)
        alert.addAction(updateDescriptionAction)
        alert.addAction(updatePriorityAction)
        alert.addAction(updateDueDateAction)
        alert.addAction(updateAssigneeAction)
        alert.addAction(cancelAction)
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        
        present(alert, animated: true)
    }
    
    private func showUpdateTitleAlert() {
        let alert = UIAlertController(title: "Update Title", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = self.task.title
            textField.placeholder = "Task Title"
        }
        
        let updateAction = UIAlertAction(title: "Update", style: .default) { [weak self] _ in
            guard let self = self,
                  let newTitle = alert.textFields?.first?.text,
                  !newTitle.isEmpty else { return }
            
            self.updateTask(title: newTitle)
        }
        
        alert.addAction(updateAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showUpdateDescriptionAlert() {
        let alert = UIAlertController(title: "Update Description", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = self.task.description
            textField.placeholder = "Task Description"
        }
        
        let updateAction = UIAlertAction(title: "Update", style: .default) { [weak self] _ in
            guard let self = self,
                  let newDescription = alert.textFields?.first?.text,
                  !newDescription.isEmpty else { return }
            
            self.updateTask(description: newDescription)
        }
        
        alert.addAction(updateAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showUpdatePriorityAlert() {
        let alert = UIAlertController(title: "Update Priority", message: nil, preferredStyle: .actionSheet)
        
        let priorities = ["low", "medium", "high"]
        for priority in priorities {
            let action = UIAlertAction(title: priority.capitalized, style: .default) { [weak self] _ in
                self?.updateTask(priority: priority)
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        
        present(alert, animated: true)
    }
    
    private func showUpdateDueDateAlert() {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        if let dueDate = task.dueDate {
            datePicker.date = dueDate
        }
        
        let alert = UIAlertController(title: "Update Due Date", message: nil, preferredStyle: .actionSheet)
        alert.view.addSubview(datePicker)
        
        let updateAction = UIAlertAction(title: "Update", style: .default) { [weak self] _ in
            let formatter = ISO8601DateFormatter()
            let dueDateString = formatter.string(from: datePicker.date)
            self?.updateTask(dueDate: dueDateString)
        }
        
        alert.addAction(updateAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        
        present(alert, animated: true)
    }
    
    private func showUpdateAssigneeAlert() {
        let alert = UIAlertController(title: "Update Assignee", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = self.task.assigneeUsername
            textField.placeholder = "Username"
        }
        
        let updateAction = UIAlertAction(title: "Update", style: .default) { [weak self] _ in
            guard let self = self,
                  let username = alert.textFields?.first?.text,
                  !username.isEmpty else { return }
            
            self.updateTask(username: username)
        }
        
        alert.addAction(updateAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func updateTask(title: String? = nil,
                          description: String? = nil,
                          priority: String? = nil,
                          dueDate: String? = nil,
                          username: String? = nil,
                          statusId: Int? = nil,
                          position: Int? = nil) {
        
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
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedTask):
                    self?.task = updatedTask
                    self?.collectionView.reloadData()
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

    private func updateTaskStatus(to status: BoardStatus) {
        updateTask(statusId: status.id)
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
            return cell
            
        case .project:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProjectCell.identifier, for: indexPath) as! ProjectCell
            cell.configure(projectName: board.name, teamName: board.name, color: UIColor(hex: board.background) ?? .systemBlue)
            return cell
            
        case .description:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DescriptionCell.identifier, for: indexPath) as! DescriptionCell
            return cell
            
        case .dates:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DateCell.identifier, for: indexPath) as! DateCell
            cell.configure(title: indexPath.item == 0 ? "Başlangıç tarihi" : "Bitiş tarihi")
            return cell
            
        case .members:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MemberCell.identifier, for: indexPath) as! MemberCell
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
