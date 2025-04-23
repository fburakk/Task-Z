//import UIKit
//
//class TaskCell: UICollectionViewCell {
//    static let identifier = "TaskCell"
//    
//    // MARK: - UI Components
//    private let containerView: UIView = {
//        let view = UIView()
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.backgroundColor = UIColor(white: 0.15, alpha: 1.0) // Dark gray background
//        view.layer.cornerRadius = 8
//        return view
//    }()
//    
//    private let titleLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = .systemFont(ofSize: 16)
//        label.textColor = .white
//        label.numberOfLines = 2
//        return label
//    }()
//    
//    private let initialsView: UIView = {
//        let view = UIView()
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.backgroundColor = .systemBlue
//        view.layer.cornerRadius = 12
//        return view
//    }()
//    
//    private let initialsLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = .systemFont(ofSize: 12, weight: .medium)
//        label.textColor = .white
//        label.textAlignment = .center
//        return label
//    }()
//    
//    // MARK: - Initialization
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupUI()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    // MARK: - Setup
//    private func setupUI() {
//        contentView.backgroundColor = .clear
//        
//        contentView.addSubview(containerView)
//        containerView.addSubview(titleLabel)
//        containerView.addSubview(initialsView)
//        initialsView.addSubview(initialsLabel)
//        
//        NSLayoutConstraint.activate([
//            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//            
//            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
//            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
//            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -48),
//            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
//            
//            initialsView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
//            initialsView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
//            initialsView.widthAnchor.constraint(equalToConstant: 24),
//            initialsView.heightAnchor.constraint(equalToConstant: 24),
//            
//            initialsLabel.centerXAnchor.constraint(equalTo: initialsView.centerXAnchor),
//            initialsLabel.centerYAnchor.constraint(equalTo: initialsView.centerYAnchor)
//        ])
//    }
//    
//    // MARK: - Configuration
//    func configure(with task: Task) {
//        titleLabel.text = task.title
//        
//        // Set initials from createdBy (assuming it's a name or username)
//        let initials = task.createdBy.split(separator: " ")
//            .prefix(2)
//            .compactMap { $0.first }
//            .map(String.init)
//            .joined()
//            .uppercased()
//        
//        initialsLabel.text = initials
//    }
//    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        titleLabel.text = nil
//        initialsLabel.text = nil
//    }
//} 
