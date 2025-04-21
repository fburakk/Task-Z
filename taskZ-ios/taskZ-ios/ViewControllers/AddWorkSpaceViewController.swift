//
//  AddWorkSpaceViewController.swift
//  taskZ-ios
//
//  Created by Burak Köse on 18.04.2025.
//

import UIKit

extension Notification.Name {
    static let workspaceCreated = Notification.Name("workspaceCreated")
    static let workspaceDeleted = Notification.Name("workspaceDeleted")
}

class WorkspaceCell: UICollectionViewCell {
    static let identifier = "WorkspaceCell"
    
    private let folderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "folder.fill")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .secondarySystemGroupedBackground
        
        [folderImageView, titleLabel, chevronImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            folderImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            folderImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            folderImageView.widthAnchor.constraint(equalToConstant: 24),
            folderImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: folderImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            chevronImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with workspace: Workspace) {
        titleLabel.text = workspace.name
    }
}

protocol WorkspaceSelectionViewControllerDelegate: AnyObject {
    func didSelectWorkspace(_ workspace: Workspace)
}

class WorkspaceSelectionViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: WorkspaceSelectionViewControllerDelegate?
    private var workspaces: [Workspace] = []
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        return indicator
    }()
    
    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(WorkspaceCell.self, forCellWithReuseIdentifier: WorkspaceCell.identifier)
        return collectionView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadWorkspaces()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(collectionView)
        view.addSubview(loadingIndicator)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        title = "Çalışma Alanı"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addWorkspaceButtonTapped)
        )
    }
    
    private func loadWorkspaces() {
        loadingIndicator.startAnimating()
        
        APIService.shared.getAllWorkspaces { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                
                switch result {
                case .success(let workspaces):
                    self.workspaces = workspaces
                    self.collectionView.reloadData()
                case .failure(let error):
                    self.showError(error)
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        let apiError = APIError.handleError(error)
        let alert = UIAlertController(
            title: "Hata",
            message: apiError.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            config.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
                self?.createSwipeActions(for: indexPath)
            }
            let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
            return section
        }
        return layout
    }
    
    private func createSwipeActions(for indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Don't allow deleting the last workspace
        guard workspaces.count > 1 else { return nil }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Sil") { [weak self] (action, view, completion) in
            guard let self = self else {
                completion(false)
                return
            }
            
            let workspace = self.workspaces[indexPath.item]
            let alert = UIAlertController(
                title: "Çalışma Alanını Sil",
                message: "'\(workspace.name)' çalışma alanını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "İptal", style: .cancel) { _ in
                completion(false)
            })
            
            alert.addAction(UIAlertAction(title: "Sil", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                
                self.loadingIndicator.startAnimating()
                APIService.shared.deleteWorkspace(id: workspace.id) { [weak self] result in
                    guard let self = self else { return }
                    
                    DispatchQueue.main.async {
                        self.loadingIndicator.stopAnimating()
                        
                        switch result {
                        case .success:
                            self.workspaces.remove(at: indexPath.item)
                            self.collectionView.performBatchUpdates({
                                self.collectionView.deleteItems(at: [indexPath])
                            }, completion: { _ in
                                NotificationCenter.default.post(name: .workspaceDeleted, object: nil, userInfo: ["workspace": workspace])
                                completion(true)
                            })
                        case .failure(let error):
                            self.showError(error)
                            completion(false)
                        }
                    }
                }
            })
            
            self.present(alert, animated: true)
        }
        
        deleteAction.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    // MARK: - Actions
    @objc private func addWorkspaceButtonTapped() {
        let alert = UIAlertController(title: "Yeni Çalışma Alanı", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Çalışma Alanı Adı"
        }
        
        let createAction = UIAlertAction(title: "Oluştur", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?.first?.text,
                  !name.isEmpty else { return }
            
            self.loadingIndicator.startAnimating()
            APIService.shared.createWorkspace(name: name) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    
                    switch result {
                    case .success(let newWorkspace):
                        self.workspaces.append(newWorkspace)
                        self.collectionView.reloadData()
                        NotificationCenter.default.post(name: .workspaceCreated, object: nil, userInfo: ["workspace": newWorkspace])
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

// MARK: - UICollectionViewDataSource
extension WorkspaceSelectionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return workspaces.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WorkspaceCell.identifier, for: indexPath) as! WorkspaceCell
        let workspace = workspaces[indexPath.item]
        cell.configure(with: workspace)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension WorkspaceSelectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let workspace = workspaces[indexPath.item]
        delegate?.didSelectWorkspace(workspace)
        navigationController?.popViewController(animated: true)
    }
}
