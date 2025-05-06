import UIKit

// MARK: - TaskHeaderCell
protocol TaskHeaderCellDelegate: AnyObject {
    func taskHeaderCell(_ cell: TaskHeaderCell, didUpdateTitle title: String)
}

class TaskHeaderCell: UICollectionViewCell {
    static let identifier = "TaskHeaderCell"
    
    weak var delegate: TaskHeaderCellDelegate?
    
    private let titleTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = .systemFont(ofSize: 20, weight: .bold)
        textField.textColor = .white
        return textField
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(titleTextField)
        
        NSLayoutConstraint.activate([
            titleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleTextField.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleTextField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        titleTextField.addTarget(self, action: #selector(titleDidChange), for: .editingChanged)
    }
    
    @objc private func titleDidChange() {
        if let text = titleTextField.text {
            delegate?.taskHeaderCell(self, didUpdateTitle: text)
        }
    }
    
    func configure(with task: Task) {
        titleTextField.text = task.title
    }
}

// MARK: - ProjectCell
class ProjectCell: UICollectionViewCell {
    static let identifier = "ProjectCell"
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let colorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 4
        return view
    }()
    
    private let projectNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        return label
    }()
    
    private let teamNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(colorView)
        containerView.addSubview(projectNameLabel)
        containerView.addSubview(teamNameLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            colorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            colorView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            colorView.widthAnchor.constraint(equalToConstant: 24),
            colorView.heightAnchor.constraint(equalToConstant: 24),
            
            projectNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            projectNameLabel.leadingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: 12),
            projectNameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            teamNameLabel.topAnchor.constraint(equalTo: projectNameLabel.bottomAnchor, constant: 4),
            teamNameLabel.leadingAnchor.constraint(equalTo: projectNameLabel.leadingAnchor),
            teamNameLabel.trailingAnchor.constraint(equalTo: projectNameLabel.trailingAnchor),
            teamNameLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(projectName: String, teamName: String, color: UIColor) {
        projectNameLabel.text = projectName
        teamNameLabel.text = teamName
        colorView.backgroundColor = color
    }
}

// MARK: - DescriptionCell
protocol DescriptionCellDelegate: AnyObject {
    func descriptionCell(_ cell: DescriptionCell, didUpdateDescription description: String)
}

class DescriptionCell: UICollectionViewCell {
    static let identifier = "DescriptionCell"
    
    weak var delegate: DescriptionCellDelegate?
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "text.alignleft", withConfiguration: config)
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .white
        return imageView
    }()
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Açıklama Ekleyin"
        textField.textColor = .white
        textField.font = .systemFont(ofSize: 16)
        textField.backgroundColor = .clear
        return textField
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(textField)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 44),
            
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            textField.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        textField.addTarget(self, action: #selector(descriptionDidChange), for: .editingChanged)
    }
    
    @objc private func descriptionDidChange() {
        if let text = textField.text {
            delegate?.descriptionCell(self, didUpdateDescription: text)
        }
    }
    
    func configure(description: String?) {
        textField.text = description
    }
}

// MARK: - DateCell
protocol DateCellDelegate: AnyObject {
    func dateCell(_ cell: DateCell, didUpdateDate date: Date?)
}

class DateCell: UICollectionViewCell {
    static let identifier = "DateCell"
    
    weak var delegate: DateCellDelegate?
    private var datePicker: UIDatePicker?
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "clock", withConfiguration: config)
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .white
        return imageView
    }()
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textColor = .white
        textField.font = .systemFont(ofSize: 16)
        textField.backgroundColor = .clear
        return textField
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(textField)
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(dateDidChange), for: .valueChanged)
        textField.inputView = datePicker
        self.datePicker = datePicker
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 44),
            
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            textField.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    
    @objc private func dateDidChange() {
        if let date = datePicker?.date {
            delegate?.dateCell(self, didUpdateDate: date)
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            textField.text = formatter.string(from: date)
        }
    }
    
    func configure(title: String, date: Date? = nil) {
        textField.placeholder = title
        if let date = date {
            datePicker?.date = date
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            textField.text = formatter.string(from: date)
        }
    }
}

// MARK: - MemberCell
protocol MemberCellDelegate: AnyObject {
    func memberCell(_ cell: MemberCell, didUpdateUsername username: String)
}

class MemberCell: UICollectionViewCell {
    static let identifier = "MemberCell"
    
    weak var delegate: MemberCellDelegate?
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "person", withConfiguration: config)
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .white
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Üyeler"
        label.textColor = .white
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textColor = .white
        textField.font = .systemFont(ofSize: 16)
        textField.textAlignment = .right
        textField.placeholder = "Add member"
        return textField
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(usernameTextField)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 44),
            
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            usernameTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            usernameTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            usernameTextField.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12)
        ])
        
        usernameTextField.addTarget(self, action: #selector(usernameDidChange), for: .editingChanged)
    }
    
    @objc private func usernameDidChange() {
        if let text = usernameTextField.text {
            delegate?.memberCell(self, didUpdateUsername: text)
        }
    }
    
    func configure(username: String?) {
        usernameTextField.text = username
    }
}

// MARK: - StatusCell
class StatusCell: UICollectionViewCell {
    static let identifier = "StatusCell"
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "arrow.right.circle", withConfiguration: config)
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .white
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Durum"
        label.textColor = .white
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .right
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 44),
            
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            statusLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12)
        ])
    }
    
    func configure(with status: BoardStatus) {
        statusLabel.text = status.title
    }
}
