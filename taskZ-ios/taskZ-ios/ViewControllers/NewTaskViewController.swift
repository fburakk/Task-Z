import UIKit

class NewTaskViewController: UIViewController {
    var onCreate: ((String, String, String, Date?) -> Void)?

    private let containerView = UIView()
    private let titleField = UITextField()
    private let descriptionField = UITextField()
    private let priorityField = UITextField()
    private let dateField = UITextField()
    private let priorityPicker = UIPickerView()
    private let datePicker = UIDatePicker()
    private let cancelButton = UIButton(type: .system)
    private let createButton = UIButton(type: .system)
    private let priorities = ["Low", "Medium", "High"]
    private var selectedPriority = "Medium"
    private var selectedDate: Date?
    private var tempSelectedPriority: String?
    private var tempSelectedDate: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPickers()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(white: 0.13, alpha: 1)
        containerView.layer.cornerRadius = 18
        view.addSubview(containerView)

        // Title
        let titleIcon = UIImageView(image: UIImage(systemName: "textformat"))
        titleIcon.tintColor = .white
        titleIcon.translatesAutoresizingMaskIntoConstraints = false
        titleField.placeholder = "Task Title"
        titleField.textColor = .white
        titleField.backgroundColor = UIColor(white: 0.18, alpha: 1)
        titleField.layer.cornerRadius = 12
        titleField.layer.masksToBounds = true
        titleField.translatesAutoresizingMaskIntoConstraints = false
        titleField.setLeftPaddingPoints(12)
        titleField.font = .systemFont(ofSize: 16)

        // Description
        let descIcon = UIImageView(image: UIImage(systemName: "text.alignleft"))
        descIcon.tintColor = .white
        descIcon.translatesAutoresizingMaskIntoConstraints = false
        descriptionField.placeholder = "Description"
        descriptionField.textColor = .white
        descriptionField.backgroundColor = UIColor(white: 0.18, alpha: 1)
        descriptionField.layer.cornerRadius = 12
        descriptionField.layer.masksToBounds = true
        descriptionField.translatesAutoresizingMaskIntoConstraints = false
        descriptionField.setLeftPaddingPoints(12)
        descriptionField.font = .systemFont(ofSize: 16)

        // Priority
        let priorityIcon = UIImageView(image: UIImage(systemName: "flag"))
        priorityIcon.tintColor = .white
        priorityIcon.translatesAutoresizingMaskIntoConstraints = false
        priorityField.placeholder = "Priority"
        priorityField.textColor = .white
        priorityField.backgroundColor = UIColor(white: 0.18, alpha: 1)
        priorityField.layer.cornerRadius = 12
        priorityField.layer.masksToBounds = true
        priorityField.translatesAutoresizingMaskIntoConstraints = false
        priorityField.setLeftPaddingPoints(12)
        priorityField.font = .systemFont(ofSize: 16)
        priorityField.inputView = priorityPicker
        priorityField.tintColor = .clear
        priorityField.text = selectedPriority
        priorityPicker.dataSource = self
        priorityPicker.delegate = self

        // Date
        let dateIcon = UIImageView(image: UIImage(systemName: "clock"))
        dateIcon.tintColor = .white
        dateIcon.translatesAutoresizingMaskIntoConstraints = false
        dateField.placeholder = "Due Date"
        dateField.textColor = .white
        dateField.backgroundColor = UIColor(white: 0.18, alpha: 1)
        dateField.layer.cornerRadius = 12
        dateField.layer.masksToBounds = true
        dateField.translatesAutoresizingMaskIntoConstraints = false
        dateField.setLeftPaddingPoints(12)
        dateField.font = .systemFont(ofSize: 16)
        dateField.inputView = datePicker
        dateField.tintColor = .clear
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)

        // Buttons
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = UIColor(white: 0.3, alpha: 1)
        cancelButton.layer.cornerRadius = 8
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        createButton.setTitle("Create", for: .normal)
        createButton.setTitleColor(.white, for: .normal)
        createButton.backgroundColor = .systemBlue
        createButton.layer.cornerRadius = 8
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)

        // Stack for fields
        let stack = UIStackView(arrangedSubviews: [
            makeFieldRow(icon: titleIcon, field: titleField),
            makeFieldRow(icon: descIcon, field: descriptionField),
            makeFieldRow(icon: priorityIcon, field: priorityField),
            makeFieldRow(icon: dateIcon, field: dateField)
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        let buttonStack = UIStackView(arrangedSubviews: [cancelButton, createButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(stack)
        containerView.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),

            stack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            buttonStack.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 24),
            buttonStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            buttonStack.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func makeFieldRow(icon: UIView, field: UIView) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [icon, field])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        icon.widthAnchor.constraint(equalToConstant: 28).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 28).isActive = true
        field.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return stack
    }

    private func setupPickers() {
        // Priority Picker Setup
        let priorityToolbar = UIToolbar()
        priorityToolbar.sizeToFit()
        let priorityDoneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(priorityDoneTapped))
        let priorityCancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(priorityCancelTapped))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        priorityToolbar.items = [priorityCancelButton, flexSpace, priorityDoneButton]
        priorityToolbar.barTintColor = UIColor(white: 0.13, alpha: 1)
        priorityToolbar.tintColor = .systemBlue
        priorityField.inputAccessoryView = priorityToolbar

        // Date Picker Setup
        let dateToolbar = UIToolbar()
        dateToolbar.sizeToFit()
        let dateDoneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dateDoneTapped))
        let dateCancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(dateCancelTapped))
        dateToolbar.items = [dateCancelButton, flexSpace, dateDoneButton]
        dateToolbar.barTintColor = UIColor(white: 0.13, alpha: 1)
        dateToolbar.tintColor = .systemBlue
        dateField.inputAccessoryView = dateToolbar
    }

    @objc private func priorityDoneTapped() {
        selectedPriority = tempSelectedPriority ?? selectedPriority
        priorityField.text = selectedPriority
        priorityField.resignFirstResponder()
    }

    @objc private func priorityCancelTapped() {
        priorityPicker.selectRow(priorities.firstIndex(of: selectedPriority) ?? 1, inComponent: 0, animated: false)
        priorityField.resignFirstResponder()
    }

    @objc private func dateDoneTapped() {
        selectedDate = tempSelectedDate
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        if let date = selectedDate {
            dateField.text = formatter.string(from: date)
        }
        dateField.resignFirstResponder()
    }

    @objc private func dateCancelTapped() {
        tempSelectedDate = selectedDate
        dateField.resignFirstResponder()
    }

    @objc private func dateChanged(_ sender: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateField.text = formatter.string(from: sender.date)
        tempSelectedDate = sender.date
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func createTapped() {
        guard let title = titleField.text, !title.isEmpty else { return }
        let desc = descriptionField.text ?? ""
        let date = selectedDate
        let priority = priorityField.text ?? selectedPriority
        onCreate?(title, desc, priority, date)
        dismiss(animated: true)
    }
}

extension NewTaskViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { priorities.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { priorities[row] }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        tempSelectedPriority = priorities[row]
        priorityField.text = tempSelectedPriority
    }
}

// Padding helper
private extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
} 