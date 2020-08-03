import UIKit
import WordPressKit

/// PasswordViewController: view to enter WP account password.
///
class PasswordViewController: LoginViewController {
    
    // MARK: - Properties
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?
    
    private weak var passwordField: UITextField?
    private var rows = [Row]()
    private var errorMessage: String?

    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .loginWPComPassword
        }
    }
    
    // Required for `NUXKeyboardResponder` but unused here.
    var verticalCenterConstraint: NSLayoutConstraint?
    // TODO: implement NUXKeyboardResponder support
    
    // MARK: - View
    
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

extension PasswordViewController: UITableViewDataSource {
    
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

// MARK: - Validation and Continue

private extension PasswordViewController {
    
    // MARK: - Button Actions
    
    @IBAction func handleContinueButtonTapped(_ sender: NUXButton) {
        // TODO: passwordy stuff
    }
    
}

// MARK: - Table Management

private extension PasswordViewController {
    
    /// Registers all of the available TableViewCells.
    ///
    func registerTableViewCells() {
        let cells = [
            GravatarEmailTableViewCell.reuseIdentifier: GravatarEmailTableViewCell.loadNib(),
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
        rows = [.gravatarEmail]
        
        // Instructions only for social accounts
        if loginFields.meta.socialService != nil {
            rows.append(.instructions)
        }
        
        rows.append(.password)
        
        if errorMessage != nil {
            rows.append(.errorMessage)
        }
        
        rows.append(.forgotPassword)
    }
    
    /// Configure cells.
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as GravatarEmailTableViewCell:
            configureGravatarEmail(cell)
        case let cell as TextLabelTableViewCell where row == .instructions:
            configureInstructionLabel(cell)
        case let cell as TextFieldTableViewCell where row == .password:
            configurePasswordTextField(cell)
        case let cell as TextLinkButtonTableViewCell:
            configureTextLinkButton(cell)
        case let cell as TextLabelTableViewCell where row == .errorMessage:
            configureErrorLabel(cell)
        default:
            DDLogError("Error: Unidentified tableViewCell type found.")
        }
    }
    
    /// Configure the gravtar + email cell.
    ///
    func configureGravatarEmail(_ cell: GravatarEmailTableViewCell) {
        // TODO: update with user info
        cell.configureImage(UIImage.gridicon(.userCircle), text: "unknownuser@example.com")
    }
    
    /// Configure the instruction cell.
    ///
    func configureInstructionLabel(_ cell: TextLabelTableViewCell) {
        // Instructions only for social accounts
        guard let service = loginFields.meta.socialService else {
            return
        }

        let displayStrings = WordPressAuthenticator.shared.displayStrings
        let instructions = (service == .google) ? displayStrings.googlePasswordInstructions :
                                                  displayStrings.applePasswordInstructions

        cell.configureLabel(text: instructions)
    }
    
    /// Configure the password textfield cell.
    ///
    func configurePasswordTextField(_ cell: TextFieldTableViewCell) {
        cell.configureTextFieldStyle(with: .password,
                                     and: WordPressAuthenticator.shared.displayStrings.passwordPlaceholder)
        // Save a reference to the first textField so it can becomeFirstResponder.
        passwordField = cell.textField
        
        // TODO: implement textField delegate
        // cell.textField.delegate = self
        
        SigninEditingState.signinEditingStateActive = true
    }
    
    /// Configure the link cell.
    ///
    func configureTextLinkButton(_ cell: TextLinkButtonTableViewCell) {
        cell.configureButton(text: WordPressAuthenticator.shared.displayStrings.resetPasswordButtonTitle, accessibilityTrait: .link)
        cell.actionHandler = { [weak self] in
            // TODO: handle tap
        }
    }
    
    /// Configure the error message cell.
    ///
    func configureErrorLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: errorMessage, style: .error)
    }
    
    
    /// Rows listed in the order they were created.
    ///
    enum Row {
        case gravatarEmail
        case instructions
        case password
        case forgotPassword
        case errorMessage
        
        var reuseIdentifier: String {
            switch self {
            case .gravatarEmail:
                return GravatarEmailTableViewCell.reuseIdentifier
            case .instructions:
                return TextLabelTableViewCell.reuseIdentifier
            case .password:
                return TextFieldTableViewCell.reuseIdentifier
            case .forgotPassword:
                return TextLinkButtonTableViewCell.reuseIdentifier
            case .errorMessage:
                return TextLabelTableViewCell.reuseIdentifier
            }
        }
    }
}
