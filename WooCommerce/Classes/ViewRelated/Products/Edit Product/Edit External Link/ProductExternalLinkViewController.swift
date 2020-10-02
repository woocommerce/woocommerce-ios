import UIKit
import Yosemite

/// Contains text fields for editing an external product's external URL and button text.
final class ProductExternalLinkViewController: UIViewController {
    private lazy var tableView: UITableView = {
        return UITableView(frame: .zero, style: .grouped)
    }()

    private let product: Product
    private var sections: [Section] = []

    private var externalURL: String?
    private var buttonText: String

    private var error: String?

    private lazy var keyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
        self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
    }

    typealias Completion = (_ externalURL: String?, _ buttonText: String) -> Void
    private let onCompletion: Completion

    init(product: Product, onCompletion: @escaping Completion) {
        self.product = product
        self.externalURL = product.externalURL
        self.buttonText = product.buttonText.isNotEmpty ? product.buttonText : Strings.buyProductPlaceholder
        self.onCompletion = onCompletion

        super.init(nibName: nil, bundle: nil)

        reloadSections()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureTableView()
        startObservingKeyboardNotifications()
    }
}

// MARK: - Navigation actions handling
//
extension ProductExternalLinkViewController {
    override func shouldPopOnBackButton() -> Bool {
        guard hasUnsavedChanges() else {
            return true
        }
        presentBackNavigationActionSheet()
        return false
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    @objc private func completeEditing() {
        ServiceLocator.analytics.track(.externalProductLinkSettingsDoneButtonTapped, withProperties: [
            "has_changed_data": hasUnsavedChanges()
        ])
        onCompletion(externalURL, buttonText)
    }

    private func hasUnsavedChanges() -> Bool {
        return externalURL != product.externalURL || buttonText != product.buttonText
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

extension ProductExternalLinkViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer
    }
}

// MARK: - Support for UITableViewDataSource
//
private extension ProductExternalLinkViewController {
    func reloadSections() {
        sections = [
            Section(errorTitle: error, footer: Strings.externalURLFooter, rows: [.externalURL]),
            Section(footer: Strings.buttonTextFooter, rows: [.buttonText])
        ]

        tableView.reloadData()
        configureTextFieldFirstResponder()
    }

    /// Configure cellForRowAtIndexPath:
    ///
   func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TitleAndTextFieldTableViewCell where row == .externalURL:
            configureExternalURL(cell: cell)
        case let cell as TitleAndTextFieldTableViewCell where row == .buttonText:
            configureButtonText(cell: cell)
        default:
            fatalError("Unexpected row: \(row)")
        }
    }

    func configureExternalURL(cell: TitleAndTextFieldTableViewCell) {
        let title = Strings.productURLTitle
        let placeholder = Strings.enterURLPlaceholder
        var viewModel = TitleAndTextFieldTableViewCell.ViewModel(title: title,
                                                                 text: externalURL,
                                                                 placeholder: placeholder,
                                                                 keyboardType: .URL,
                                                                 textFieldAlignment: .trailing,
                                                                 onTextChange: { [weak self] text in
                                                                    self?.externalURL = text
                                                                    if text?.isValidURL() == true || text?.isEmpty == true {
                                                                        self?.hideError()
                                                                    } else {
                                                                        self?.displayError(error: Strings.errorMalformedURL)
                                                                    }
        })
        viewModel = viewModel.stateUpdated(state: error == nil ? .normal : .error)
        cell.configure(viewModel: viewModel)
    }

    func configureButtonText(cell: TitleAndTextFieldTableViewCell) {
        let title = Strings.buttonTextTitle
        let placeholder = Strings.buyProductPlaceholder
        let viewModel = TitleAndTextFieldTableViewCell.ViewModel(title: title,
                                                                 text: buttonText,
                                                                 placeholder: placeholder,
                                                                 textFieldAlignment: .trailing,
                                                                 onTextChange: { [weak self] text in
                                                                    self?.buttonText = text ?? ""
        })
        cell.configure(viewModel: viewModel)
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension ProductExternalLinkViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = sections[section]
        guard let errorTitle = section.errorTitle else {
            return nil
        }

        let headerID = ErrorSectionHeaderView.reuseIdentifier
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerID) as? ErrorSectionHeaderView else {
            fatalError()
        }
        headerView.configure(title: errorTitle)
        UIAccessibility.post(notification: .layoutChanged, argument: headerView)
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = sections[section]
        guard let errorTitle = section.errorTitle, errorTitle.isEmpty == false else {
            return 0
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        let section = sections[section]
        guard let errorTitle = section.errorTitle, errorTitle.isEmpty == false else {
            return 0
        }
        return Constants.estimatedSectionHeaderHeight
    }
}

// MARK: - View Configuration
//
private extension ProductExternalLinkViewController {
    func configureNavigation() {
        title = Strings.screenTitle

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(completeEditing))
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(tableView)

        registerTableViewCells()
        registerTableViewHeaderFooters()
    }

    func registerTableViewCells() {
        tableView.registerNib(for: TitleAndTextFieldTableViewCell.self)
    }

    func registerTableViewHeaderFooters() {
        let headersAndFooters = [ErrorSectionHeaderView.self]

        for kind in headersAndFooters {
            tableView.register(kind.loadNib(), forHeaderFooterViewReuseIdentifier: kind.reuseIdentifier)
        }
    }

    func enableDoneButton(_ enabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = enabled
    }

    // Configure the text field as first responder
    func configureTextFieldFirstResponder() {
        if let indexPath = sections.indexPathForRow(.externalURL) {
            let cell = tableView.cellForRow(at: indexPath) as? TitleAndTextFieldTableViewCell
            cell?.textFieldBecomeFirstResponder()
        }
    }
}

// MARK: - Keyboard management
//
private extension ProductExternalLinkViewController {
    /// Registers for all of the related Notifications
    ///
    func startObservingKeyboardNotifications() {
        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

extension ProductExternalLinkViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        return tableView
    }
}

// MARK: - Error handling
//
private extension ProductExternalLinkViewController {
    func displayError(error: String) {
        // This check is useful so we don't reload while typing each letter in the sections
        if self.error == nil {
            self.error = error
            reloadSections()
            enableDoneButton(false)
        }
    }

    func hideError() {
        // This check is useful so we don't reload while typing each letter in the sections
        if error != nil {
            error = nil
            reloadSections()
            enableDoneButton(true)
        }
    }
}

// MARK: - Constants
//
private extension ProductExternalLinkViewController {
    /// Table Rows
    ///
    enum Row {
        /// Listed in the order they appear on screen
        case externalURL
        case buttonText

        var reuseIdentifier: String {
            switch self {
            case .externalURL, .buttonText:
                return TitleAndTextFieldTableViewCell.reuseIdentifier
            }
        }
    }

    /// Table Sections
    ///
    struct Section: RowIterable {
        let errorTitle: String?
        let footer: String?
        let rows: [Row]

        init(errorTitle: String? = nil, footer: String? = nil, rows: [Row]) {
            self.errorTitle = errorTitle
            self.footer = footer
            self.rows = rows
        }
    }
}

private extension ProductExternalLinkViewController {
    enum Constants {
        static let estimatedSectionHeaderHeight: CGFloat = 44
    }

    enum Strings {
        static let screenTitle = NSLocalizedString("Product Link",
                                                   comment: "Edit Product External Link navigation title")
        static let productURLTitle = NSLocalizedString("Product URL",
                                                       comment: "Title of the text field for editing the external URL for an external/affiliate product")
        static let enterURLPlaceholder = NSLocalizedString("Enter URL",
                                         comment: "Placeholder of the text field for editing the external URL for an external/affiliate product")
        static let errorMalformedURL = NSLocalizedString("Check that the URL entered is valid",
                                                         comment: "The message of the alert when there is an error in the URL of an external product")
        static let externalURLFooter = NSLocalizedString("Enter the external URL to the product.",
                                                  comment: "Footer text for editing product external URL")
        static let buttonTextTitle = NSLocalizedString("Button Text",
                                                       comment: "Title of the text field for editing the button text for an external/affiliate product")
        static let buttonTextFooter = NSLocalizedString("This text will be shown on the button linking to the external product.",
                                                 comment: "Footer text for editing external product button text")
        static let buyProductPlaceholder = NSLocalizedString("Buy Product",
        comment: "Placeholder of the text field for editing the button text for an external/affiliate product")
    }
}
