import UIKit

/// TwoFAViewController: view to enter 2FA code.
///
final class TwoFAViewController: LoginViewController {

    // MARK: - Properties
    
    @IBOutlet private weak var tableView: UITableView!
    private weak var codeField: UITextField?
    
    private var rows = [Row]()
    private var errorMessage: String?

    // Required for `NUXKeyboardResponder` but unused here.
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?
    var verticalCenterConstraint: NSLayoutConstraint?

    // TODO: add support tag

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = WordPressAuthenticator.shared.displayStrings.logInTitle
        styleNavigationBar(forUnified: true)

        defaultTableViewMargin = tableViewLeadingConstraint?.constant ?? 0
        setTableViewMargins(forWidth: view.frame.width)
        
        localizePrimaryButton()
        registerTableViewCells()
        loadRows()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))
        configureViewForEditingIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }

    // MARK: - Overrides

    override func styleBackground() {
        guard let unifiedBackgroundColor = WordPressAuthenticator.shared.unifiedStyle?.viewControllerBackgroundColor else {
            super.styleBackground()
            return
        }

        view.backgroundColor = unifiedBackgroundColor
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return WordPressAuthenticator.shared.unifiedStyle?.statusBarStyle ??
               WordPressAuthenticator.shared.style.statusBarStyle
    }

}

// MARK: - UITableViewDataSource

extension TwoFAViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)
        return cell
    }

}

// MARK: - Keyboard Notifications

extension TwoFAViewController: NUXKeyboardResponder {
    
    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }

    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }

}

private extension TwoFAViewController {

    /// Registers all of the available TableViewCells.
    ///
    func registerTableViewCells() {
        let cells = [
            TextLabelTableViewCell.reuseIdentifier: TextLabelTableViewCell.loadNib(),
            TextFieldTableViewCell.reuseIdentifier: TextFieldTableViewCell.loadNib(),
            TextLinkButtonTableViewCell.reuseIdentifier: TextLinkButtonTableViewCell.loadNib()
        ]
        
        for (reuseIdentifier, nib) in cells {
            tableView.register(nib, forCellReuseIdentifier: reuseIdentifier)
        }
    }

    /// Describes how the tableView rows should be rendered.
    ///
    func loadRows() {
        rows = [.instructions, .code]

        if errorMessage != nil {
             rows.append(.errorMessage)
         }

        rows.append(.sendCode)
    }

    /// Configure cells.
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TextLabelTableViewCell where row == .instructions:
            configureInstructionLabel(cell)
        case let cell as TextFieldTableViewCell:
            configureTextField(cell)
        case let cell as TextLinkButtonTableViewCell:
            configureTextLinkButton(cell)
        case let cell as TextLabelTableViewCell where row == .errorMessage:
            configureErrorLabel(cell)
        default:
            DDLogError("Error: Unidentified tableViewCell type found.")
        }
    }
    
    /// Configure the instruction cell.
    ///
    func configureInstructionLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: WordPressAuthenticator.shared.displayStrings.twoFactorInstructions, style: .body)
    }

    /// Configure the textfield cell.
    ///
    func configureTextField(_ cell: TextFieldTableViewCell) {
        cell.configureTextFieldStyle(with: .numericCode,
                                     and: WordPressAuthenticator.shared.displayStrings.twoFactorCodePlaceholder)

        // Save a reference to the first textField so it can becomeFirstResponder.
        codeField = cell.textField
        
        // TODO: add cell.onChangeSelectionHandler here.

        SigninEditingState.signinEditingStateActive = true
    }

    /// Configure the link cell.
    ///
    func configureTextLinkButton(_ cell: TextLinkButtonTableViewCell) {
        cell.configureButton(text: WordPressAuthenticator.shared.displayStrings.textCodeButtonTitle)
        
        // TODO: add cell.actionHandler here.
    }

    /// Configure the error message cell.
    ///
    func configureErrorLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: errorMessage, style: .error)
    }

    /// Configure the view for an editing state.
    ///
    func configureViewForEditingIfNeeded() {
       // Check the helper to determine whether an editing state should be assumed.
       adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
       if SigninEditingState.signinEditingStateActive {
           codeField?.becomeFirstResponder()
       }
    }

    /// Rows listed in the order they were created.
    ///
    enum Row {
        case instructions
        case code
        case sendCode
        case errorMessage

        var reuseIdentifier: String {
            switch self {
            case .instructions:
                return TextLabelTableViewCell.reuseIdentifier
            case .code:
                return TextFieldTableViewCell.reuseIdentifier
            case .sendCode:
                return TextLinkButtonTableViewCell.reuseIdentifier
            case .errorMessage:
                return TextLabelTableViewCell.reuseIdentifier
            }
        }
    }
}
