import UIKit


/// SiteAddressViewController: log in by Site Address.
///
final class SiteAddressViewController: LoginViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?

    // Required property declaration for `NUXKeyboardResponder` but unused here.
    var verticalCenterConstraint: NSLayoutConstraint?

    var displayStrings: WordPressAuthenticatorDisplayStrings {
        return WordPressAuthenticator.shared.displayStrings
    }

    private var rows = [Row]()

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        localizePrimaryButton()
        registerTableViewCells()
        loadRows()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))
    }

    /// Style individual ViewController backgrounds, for now.
    ///
    override func styleBackground() {
        guard let unifiedBackgroundColor = WordPressAuthenticator.shared.unifiedStyle?.viewControllerBackgroundColor else {
            super.styleBackground()
            return
        }

        view.backgroundColor = unifiedBackgroundColor
    }
}


// MARK: - UITableViewDataSource
extension SiteAddressViewController: UITableViewDataSource {
    /// Returns the number of rows in a section
    ///
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    /// Configure cells delegate method
    ///
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}


// MARK: - UITableViewDelegate conformance
extension SiteAddressViewController: UITableViewDelegate {

}


// MARK: - Keyboard Notifications
extension SiteAddressViewController: NUXKeyboardResponder {
    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }

    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }
}



private extension SiteAddressViewController {
    // MARK: - Private methods

    /// Localize the "Continue" button
    ///
    func localizePrimaryButton() {
        let primaryTitle = displayStrings.continueButtonTitle
        submitButton?.setTitle(primaryTitle, for: .normal)
        submitButton?.setTitle(primaryTitle, for: .highlighted)
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        let cells = [
            InstructionTableViewCell.reuseIdentifier: InstructionTableViewCell.loadNib(),
            TextFieldTableViewCell.reuseIdentifier: TextFieldTableViewCell.loadNib(),
            TextButtonTableViewCell.reuseIdentifier: TextButtonTableViewCell.loadNib()
        ]

        for (reuseIdentifier, nib) in cells {
            tableView.register(nib, forCellReuseIdentifier: reuseIdentifier)
        }
    }

    /// Describes how the tableView rows should be rendered.
    ///
    func loadRows() {
        rows = [.instructions, .siteAddress]
    }

    /// Configure cells
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as InstructionTableViewCell:
            configureInstruction(cell)
        case let cell as TextFieldTableViewCell:
            configureTextField(cell)
        case let cell as TextButtonTableViewCell:
            configureTextButton(cell)
        default:
            DDLogError("Error: Unidentified tableViewCell type found.")
        }
    }

    /// Configure the instruction cell
    ///
    func configureInstruction(_ cell: InstructionTableViewCell) {
        cell.instructionText = displayStrings.siteLoginInstructions
    }

    /// Configure the textfield cell
    ///
    func configureTextField(_ cell: TextFieldTableViewCell) {
        let placeholderText = NSLocalizedString("example.com", comment: "Site Address placeholder")
        cell.configureTextFieldStyle(with: .url, and: placeholderText)
    }

    /// Configure the plain text button cell
    ///
    func configureTextButton(_ cell: TextButtonTableViewCell) {
        cell.buttonText = displayStrings.resetPasswordButtonTitle
    }

    // MARK: - Private Constants

    /// Rows listed in the order they were created
    ///
    enum Row {
        case instructions
        case siteAddress
        case resetPassword

        var reuseIdentifier: String {
            switch self {
            case .instructions:
                return InstructionTableViewCell.reuseIdentifier
            case .siteAddress:
                return TextFieldTableViewCell.reuseIdentifier
            case .resetPassword:
                return TextButtonTableViewCell.reuseIdentifier
            }
        }
    }
}
