import UIKit
import Yosemite

/// Contains text fields for editing an external product's external URL and button text.
final class ProductExternalLinkViewController: UIViewController {
    private lazy var tableView: UITableView = {
        return UITableView(frame: .zero, style: .grouped)
    }()

    private let product: Product
    private let sections: [Section]

    private var externalURL: String?
    private var buttonText: String

    private lazy var keyboardFrameObserver: KeyboardFrameObserver = {
        let keyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
            self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
        }
        return keyboardFrameObserver
    }()

    typealias Completion = (_ externalURL: String?, _ buttonText: String) -> Void
    private let onCompletion: Completion

    init(product: Product, onCompletion: @escaping Completion) {
        self.product = product
        self.externalURL = product.externalURL
        self.buttonText = product.buttonText
        self.onCompletion = onCompletion

        let externalURLFooter = NSLocalizedString("Enter the external URL to the product.",
                                                  comment: "Footer text for editing product external URL")
        let buttonTextFooter = NSLocalizedString("This text will be shown on the button linking to the external product.",
                                                 comment: "Footer text for editing external product button text")
        self.sections = [
            Section(footer: externalURLFooter, rows: [.externalURL]),
            Section(footer: buttonTextFooter, rows: [.buttonText])
        ]

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureTableView()
        startListeningToNotifications()
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
        let title = NSLocalizedString("Product URL", comment: "Title of the text field for editing the external URL for an external/affiliate product")
        let placeholder = NSLocalizedString("Enter URL",
                                            comment: "Placeholder of the text field for editing the external URL for an external/affiliate product")
        let viewModel = TitleAndTextFieldTableViewCell.ViewModel(title: title,
                                                                 text: externalURL,
                                                                 placeholder: placeholder,
                                                                 keyboardType: .URL,
                                                                 textFieldAlignment: .trailing,
                                                                 onTextChange: { [weak self] text in
                                                                    self?.externalURL = text
        })
        cell.configure(viewModel: viewModel)
    }

    func configureButtonText(cell: TitleAndTextFieldTableViewCell) {
        let title = NSLocalizedString("Button Text", comment: "Title of the text field for editing the button text for an external/affiliate product")
        let placeholder = NSLocalizedString("Buy product",
                                            comment: "Placeholder of the text field for editing the button text for an external/affiliate product")
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

// MARK: - View Configuration
//
private extension ProductExternalLinkViewController {
    func configureNavigation() {
        title = NSLocalizedString("Product Link", comment: "Edit Product External Link navigation title")

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(completeEditing))
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.dataSource = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(tableView)

        registerTableViewCells()
    }

    func registerTableViewCells() {
        tableView.register(TitleAndTextFieldTableViewCell.loadNib(), forCellReuseIdentifier: TitleAndTextFieldTableViewCell.reuseIdentifier)
    }
}

// MARK: - Keyboard management
//
private extension ProductExternalLinkViewController {
    /// Registers for all of the related Notifications
    ///
    func startListeningToNotifications() {
        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

extension ProductExternalLinkViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        return tableView
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
        let footer: String?
        let rows: [Row]

        init(footer: String? = nil, rows: [Row]) {
            self.footer = footer
            self.rows = rows
        }
    }
}
