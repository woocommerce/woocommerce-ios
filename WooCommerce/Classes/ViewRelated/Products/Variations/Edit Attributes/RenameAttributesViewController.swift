import UIKit
import Yosemite

final class RenameAttributesViewController: UIViewController {

    private let renameAttributesView = TextFieldWithFooterView()

    private let onCompletion: (String) -> Void

    private let viewModel: RenameAttributesViewModel

    /// Initializer for `RenameAttributesViewController`
    ///
    init(viewModel: RenameAttributesViewModel,
         onCompletion: @escaping (String) -> Void) {
        self.viewModel = viewModel
        self.onCompletion = onCompletion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureMainView()
        enableDoneButton(true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        renameAttributesView.becomeFirstResponder()
    }

    // MARK: - View Configuration

    func configureNavigationBar() {
        removeNavigationBackBarButtonText()
        title = Localization.title

        let rightBarButton = UIBarButtonItem(barButtonSystemItem: .done,
                                             target: self,
                                             action: #selector(doneButtonTapped))
        navigationItem.setRightBarButton(rightBarButton, animated: false)
    }

    func enableDoneButton(_ enabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = enabled
    }

    func configureMainView() {
        view.backgroundColor = .listBackground

        view.addSubview(renameAttributesView)
        renameAttributesView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            renameAttributesView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            renameAttributesView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            renameAttributesView.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 35)
        ])

        let viewModel = TextFieldWithFooterView.ViewModel(textFieldText: self.viewModel.attributeName,
                                                          footerText: Localization.footerText,
                                                          placeholder: Localization.placeholder,
                                                          onTextChange: { [weak self] newAttributeName in
                                                            guard let self = self else {return}
                                                            self.viewModel.handleAttributeNameChange(newAttributeName)
                                                            self.enableDoneButton(self.viewModel.shouldEnableDoneButton)
                                                          },
                                                          onTextDidReturn: { [weak self] _ in
                                                            self?.doneButtonTapped()
                                                          },
                                                          returnKeyType: .done)
        renameAttributesView.configure(viewModel: viewModel)
    }

    // MARK: - Navigation Actions Handling
    @objc private func doneButtonTapped() {
        onCompletion(viewModel.attributeName)
    }

    override func shouldPopOnBackButton() -> Bool {
        guard viewModel.hasUnsavedChanges() else {
            return true
        }
        presentBackNavigationActionSheet()
        return false
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

// MARK: - Constants
private extension RenameAttributesViewController {

    enum Localization {
        static let title = NSLocalizedString("Rename Attribute", comment: "Navigation title for the Rename Attributes screen")
        static let placeholder = NSLocalizedString("Attribute name", comment: "Placeholder in the Attribute Name row on Rename Attributes screen.")
        static let footerText = NSLocalizedString("This is the type of variation like size or color",
        comment: "Footer text in Rename Attributes screen")
    }
}
