import UIKit

/// Contains a text field with footer text. This view looks like a single `TextFieldTableViewCell` with a footer,
/// but is designed to be used outside of a table view.
///
final class TextFieldWithFooterView: UIView {

    struct ViewModel {
        let textFieldText: String?
        let footerText: String?
        let placeholder: String?
        let onTextChange: ((_ text: String?) -> Void)?
        let onTextDidReturn: ((_ text: String?) -> Void)?
        var returnKeyType: UIReturnKeyType = .default
    }

    private var viewModel: ViewModel?

    private var textField = UITextField()
    private let footerLabel = UILabel()

    private lazy var textFieldContainerView: UIView = {
        let container = UIView()
        container.addSubview(textField)
        return container
    }()

    // MARK: - Initializers
    init() {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(viewModel: ViewModel) {
        configureTextField(viewModel: viewModel)
        configureFooter(viewModel: viewModel)
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    private func configureTextField(viewModel: ViewModel) {
        self.viewModel = viewModel

        textField.delegate = self
        textField.text = viewModel.textFieldText
        textField.placeholder = viewModel.placeholder
        textField.returnKeyType = viewModel.returnKeyType
        textField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)

        // Style the container view
        textFieldContainerView.translatesAutoresizingMaskIntoConstraints = false
        textFieldContainerView.backgroundColor = .listForeground
        textFieldContainerView.layer.borderWidth = 0.33
        textFieldContainerView.layer.borderColor = UIColor.separator.cgColor

        // Style the text field
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.keyboardType = .default
        textField.clearButtonMode = .whileEditing
        textField.backgroundColor = .listForeground
        textField.applyBodyStyle()
    }

    private func configureFooter(viewModel: ViewModel) {
        self.viewModel = viewModel

        footerLabel.text = viewModel.footerText

        // Style the footer
        footerLabel.translatesAutoresizingMaskIntoConstraints = false
        footerLabel.applyFootnoteStyle()
    }

    // MARK: - Layout

    private func setupLayout() {
        addSubview(textFieldContainerView)
        pinSubviewToAllEdges(textFieldContainerView)
        addSubview(footerLabel)

        layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

        NSLayoutConstraint.activate([
            textFieldContainerView.heightAnchor.constraint(equalToConstant: 43),
            textFieldContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textFieldContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),

            textField.centerYAnchor.constraint(equalTo: textFieldContainerView.centerYAnchor),
            textField.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            textField.trailingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.trailingAnchor),

            footerLabel.topAnchor.constraint(equalTo: textFieldContainerView.bottomAnchor, constant: 8),
            footerLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            footerLabel.trailingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.trailingAnchor)
        ])
    }
}

private extension TextFieldWithFooterView {
    @objc func textFieldDidChange(textField: UITextField) {
        viewModel?.onTextChange?(textField.text)
    }
}

extension TextFieldWithFooterView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        viewModel?.onTextDidReturn?(textField.text)
        textField.resignFirstResponder()
        return true
    }
}
