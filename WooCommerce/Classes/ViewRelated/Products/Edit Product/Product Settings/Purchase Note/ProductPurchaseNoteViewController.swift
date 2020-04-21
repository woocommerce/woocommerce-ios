import UIKit
import Yosemite

final class ProductPurchaseNoteViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    // Completion callback
    //
    typealias Completion = (_ productSettings: ProductSettings) -> Void
    private let onCompletion: Completion

    private let productSettings: ProductSettings

    private let sections: [Section]

    private lazy var keyboardFrameObserver: KeyboardFrameObserver = {
        let keyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
            self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
        }
        return keyboardFrameObserver
    }()

    /// Init
    ///
    init(settings: ProductSettings, completion: @escaping Completion) {
        productSettings = settings
        let footerText = NSLocalizedString("An optional note to send the customer after purchase",
                                           comment: "Footer text in Product Purchase Note screen")
        sections = [Section(footer: footerText, rows: [.purchaseNote])]
        onCompletion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureMainView()
        configureTableView()
        startListeningToNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onCompletion(productSettings)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        configureTextViewFirstResponder()
    }

}

// MARK: - View Configuration
//
private extension ProductPurchaseNoteViewController {

    func configureNavigationBar() {
        title = NSLocalizedString("Purchase Note", comment: "Product Note navigation title")

        removeNavigationBackBarButtonText()
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.register(TextViewTableViewCell.loadNib(), forCellReuseIdentifier: TextViewTableViewCell.reuseIdentifier)

        tableView.dataSource = self
        tableView.delegate = self

        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()
    }

    /// Since there is only a text view in this view, the text view become the first responder immediately when the view did appear
    ///
    func configureTextViewFirstResponder() {
        if let indexPath = sections.getIndexPathForRow(.purchaseNote) {
            let cell = tableView.cellForRow(at: indexPath) as? TextViewTableViewCell
            cell?.noteTextView.becomeFirstResponder()
        }
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ProductPurchaseNoteViewController: UITableViewDataSource {

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
}

// MARK: - UITableViewDelegate Conformance
//
extension ProductPurchaseNoteViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer
    }
}

// MARK: - Support for UITableViewDataSource
//
private extension ProductPurchaseNoteViewController {
    /// Configure cellForRowAtIndexPath:
    ///
   func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TextViewTableViewCell:
            configurePurchaseNote(cell: cell)
        default:
            fatalError("Unidentified product purchase note row type")
        }
    }

    func configurePurchaseNote(cell: TextViewTableViewCell) {
        cell.iconImage = nil
        cell.noteTextView.placeholder = NSLocalizedString("Add a purchase note...", comment: "Placeholder text in Product Purchase Note screen")
        cell.noteTextView.text = productSettings.purchaseNote?.strippedHTML
        cell.noteTextView.onTextChange = { [weak self] (text) in
            self?.productSettings.purchaseNote = text
        }
    }
}

// MARK: - Keyboard management
//
private extension ProductPurchaseNoteViewController {
    /// Registers for all of the related Notifications
    ///
    func startListeningToNotifications() {
        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

extension ProductPurchaseNoteViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        return tableView
    }
}

// MARK: - Constants
//
private extension ProductPurchaseNoteViewController {

    /// Table Rows
    ///
    enum Row {
        /// Listed in the order they appear on screen
        case purchaseNote

        var reuseIdentifier: String {
            switch self {
            case .purchaseNote:
                return TextViewTableViewCell.reuseIdentifier
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
