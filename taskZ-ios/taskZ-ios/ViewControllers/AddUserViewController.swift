import UIKit

protocol AddUserViewControllerDelegate: AnyObject {
    func addUserViewController(_ viewController: AddUserViewController, didAddUser user: BoardUser)
    func addUserViewControllerDidCancel(_ viewController: AddUserViewController)
}

class AddUserViewController: UIViewController {
    weak var delegate: AddUserViewControllerDelegate?
    private let boardId: Int
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Add User"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Username"
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .systemGray6
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let roleSegmentedControl: UISegmentedControl = {
        let items = ["Viewer", "Editor"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add User", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.backgroundColor = .systemGray5
        button.setTitleColor(.systemBlue, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    init(boardId: Int) {
        self.boardId = boardId
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
        setupActions()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(usernameTextField)
        containerView.addSubview(roleSegmentedControl)
        containerView.addSubview(addButton)
        containerView.addSubview(cancelButton)
        containerView.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            usernameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            usernameTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            usernameTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            usernameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            roleSegmentedControl.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 20),
            roleSegmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            roleSegmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            addButton.topAnchor.constraint(equalTo: roleSegmentedControl.bottomAnchor, constant: 20),
            addButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            addButton.heightAnchor.constraint(equalToConstant: 44),
            
            cancelButton.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 12),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cancelButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func addButtonTapped() {
        guard let username = usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !username.isEmpty else {
            showError("Please enter a username")
            return
        }
        
        let role = roleSegmentedControl.selectedSegmentIndex == 0 ? "viewer" : "editor"
        
        loadingIndicator.startAnimating()
        addButton.isEnabled = false
        
        APIService.shared.addUserToBoard(boardId: boardId, username: username, role: role) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                self.addButton.isEnabled = true
                
                switch result {
                case .success(let user):
                    self.delegate?.addUserViewController(self, didAddUser: user)
                    self.dismiss(animated: true)
                case .failure(let error):
                    self.showError(error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func cancelButtonTapped() {
        delegate?.addUserViewControllerDidCancel(self)
        dismiss(animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
} 