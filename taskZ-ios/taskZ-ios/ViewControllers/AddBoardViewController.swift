//
//  AddBoardViewController.swift
//  taskZ-ios
//
//  Created by Burak Köse on 18.04.2025.
//

import UIKit

protocol CreateBoardViewControllerDelegate: AnyObject {
    func didCreateBoard()
}

// MARK: - Cell Types
enum CreateBoardCellType: Int, CaseIterable {
    case name
    case workspace
    case background
}

// MARK: - Cells
class CreateBoardNameCell: UICollectionViewCell {
    static let identifier = "CreateBoardNameCell"
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Yeni Pano"
        textField.textColor = .label
        textField.backgroundColor = .clear
        textField.tintColor = .label
        return textField
    }()
    
    var onTextChanged: ((String?) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textField.topAnchor.constraint(equalTo: contentView.topAnchor),
            textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            textField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func textFieldDidChange() {
        onTextChanged?(textField.text)
    }
    
    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }
}

class CreateBoardRowCell: UICollectionViewCell {
    static let identifier = "CreateBoardRowCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .label
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
        contentView.backgroundColor = .secondarySystemGroupedBackground
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(arrowImageView)
        
        [titleLabel, valueLabel, arrowImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            arrowImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            arrowImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 12),
            arrowImageView.heightAnchor.constraint(equalToConstant: 20),
            
            valueLabel.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -8),
            valueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}

class CreateBoardBackgroundCell: UICollectionViewCell {
    static let identifier = "CreateBoardBackgroundCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Arkaplan"
        label.textColor = .label
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    let colorPreview: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 4
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .secondarySystemGroupedBackground
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(colorPreview)
        
        [titleLabel, colorPreview].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            colorPreview.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            colorPreview.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorPreview.widthAnchor.constraint(equalToConstant: 24),
            colorPreview.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
}

class CreateBoardViewController: UIViewController {
    // MARK: - Properties
    weak var delegate: CreateBoardViewControllerDelegate?
    private var selectedWorkspace: Workspace?
    private var boardName: String = ""
    private var selectedColor: UIColor = .systemBlue
    
    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CreateBoardNameCell.self, forCellWithReuseIdentifier: CreateBoardNameCell.identifier)
        collectionView.register(CreateBoardRowCell.self, forCellWithReuseIdentifier: CreateBoardRowCell.identifier)
        collectionView.register(CreateBoardBackgroundCell.self, forCellWithReuseIdentifier: CreateBoardBackgroundCell.identifier)
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
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "Pano"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Oluştur", style: .done, target: self, action: #selector(createButtonTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(dismissView))
        
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    private func loadWorkspaces() {
        APIService.shared.getAllWorkspaces { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let workspaces):
                    if let firstWorkspace = workspaces.first {
                        self.selectedWorkspace = firstWorkspace
                        self.collectionView.reloadData()
                    }
                case .failure(let error):
                    self.showError(error)
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Hata",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            config.backgroundColor = .systemGroupedBackground
            let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
            section.contentInsets.top = 15
            return section
        }
        return layout
    }
    
    // MARK: - Actions
    @objc private func createButtonTapped() {
        guard let workspace = selectedWorkspace else { return }
        
        // Disable create button and show loading state
        navigationItem.rightBarButtonItem?.isEnabled = false
        let originalTitle = navigationItem.rightBarButtonItem?.title
        navigationItem.rightBarButtonItem?.title = "Oluşturuluyor..."
        
        APIService.shared.createBoard(
            name: boardName,
            workspaceId: workspace.id,
            background: selectedColor.toHex() ?? "FFFFFF"
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Reset button state
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                self.navigationItem.rightBarButtonItem?.title = originalTitle
                
                switch result {
                case .success:
                    self.delegate?.didCreateBoard()
                    self.dismiss(animated: true)
                case .failure(let error):
                    self.showError(error)
                }
            }
        }
    }
    
    @objc private func dismissView() {
        dismiss(animated: true)
    }
    
    private func updateCreateButtonState() {
        navigationItem.rightBarButtonItem?.isEnabled = !boardName.isEmpty && selectedWorkspace != nil
    }
}

// MARK: - UICollectionViewDataSource
extension CreateBoardViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1 // Name cell
        case 1:
            return 2 // Workspace and Background cells
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CreateBoardNameCell.identifier, for: indexPath) as! CreateBoardNameCell
            cell.text = boardName
            cell.onTextChanged = { [weak self] text in
                self?.boardName = text ?? ""
                self?.updateCreateButtonState()
            }
            return cell
        } else {
            switch indexPath.item {
            case 0:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CreateBoardRowCell.identifier, for: indexPath) as! CreateBoardRowCell
                cell.configure(title: "Çalışma Alanı", value: selectedWorkspace?.name ?? "Seçiniz")
                return cell
                
            case 1:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CreateBoardBackgroundCell.identifier, for: indexPath) as! CreateBoardBackgroundCell
                cell.colorPreview.backgroundColor = selectedColor
                return cell
                
            default:
                return UICollectionViewCell()
            }
        }
    }
}

// MARK: - UICollectionViewDelegate
extension CreateBoardViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            switch indexPath.item {
            case 0:
                showWorkspaceSelection()
            case 1:
                showColorPicker()
            default:
                break
            }
        }
    }
    
    private func showWorkspaceSelection() {
        let workspaceVC = WorkspaceSelectionViewController()
        workspaceVC.delegate = self
        navigationController?.pushViewController(workspaceVC, animated: true)
    }
    
    private func showColorPicker() {
        let colorPicker = UIColorPickerViewController()
        colorPicker.selectedColor = selectedColor
        colorPicker.delegate = self
        present(colorPicker, animated: true)
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension CreateBoardViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        selectedColor = viewController.selectedColor
        if let cell = collectionView.cellForItem(at: IndexPath(item: 1, section: 1)) as? CreateBoardBackgroundCell {
            cell.colorPreview.backgroundColor = selectedColor
        }
    }
}

// MARK: - WorkspaceSelectionViewControllerDelegate
extension CreateBoardViewController: WorkspaceSelectionViewControllerDelegate {
    func didSelectWorkspace(_ workspace: Workspace) {
        selectedWorkspace = workspace
        updateCreateButtonState()
        collectionView.reloadData()
    }
}
