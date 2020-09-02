import UIKit
import SafariServices

class GetStartedViewController: LoginViewController {

    // MARK: - Properties
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet private weak var leadingDividerLine: UIView!
    @IBOutlet private weak var leadingDividerLineWidth: NSLayoutConstraint!
    @IBOutlet private weak var dividerLabel: UILabel!
    @IBOutlet private weak var trailingDividerLine: UIView!
    @IBOutlet private weak var trailingDividerLineWidth: NSLayoutConstraint!

    private var rows = [Row]()

    // Submit button displayed in the table footer.
    private let continueButton: NUXButton = {
        let button = NUXButton()
        button.isPrimary = true
        
        let title = WordPressAuthenticator.shared.displayStrings.continueButtonTitle
        button.setTitle(title, for: .normal)
        button.setTitle(title, for: .highlighted)
        
        return button
    }()
    
    override open var sourceTag: WordPressSupportSourceTag {
        get {
            return .loginEmail
        }
    }
    
    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavBar()
        setupTable()
        registerTableViewCells()
        loadRows()
        setupContinueButton()
        configureDivider()
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

// MARK: - Private methods

private extension GetStartedViewController {

    // MARK: - Configuration
    
    func configureNavBar() {
        navigationItem.title = WordPressAuthenticator.shared.displayStrings.getStartedTitle
        styleNavigationBar(forUnified: true)
    }
    
    func setupTable() {
        defaultTableViewMargin = tableViewLeadingConstraint?.constant ?? 0
        setTableViewMargins(forWidth: view.frame.width)
    }

    func setupContinueButton() {
        let tableFooter = UIView(frame: Constants.footerFrame)
        tableFooter.addSubview(continueButton)
        tableFooter.pinSubviewToSafeArea(continueButton, insets: Constants.footerButtonInsets)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.isEnabled = false
        continueButton.addTarget(self, action: #selector(handleSubmitButtonTapped(_:)), for: .touchUpInside)
        tableView.tableFooterView = tableFooter
    }

    /// Style the "OR" divider.
    ///
    func configureDivider() {
        let color = WordPressAuthenticator.shared.unifiedStyle?.borderColor ?? WordPressAuthenticator.shared.style.primaryNormalBorderColor
        leadingDividerLine.backgroundColor = color
        leadingDividerLineWidth.constant = WPStyleGuide.hairlineBorderWidth
        trailingDividerLine.backgroundColor = color
        trailingDividerLineWidth.constant = WPStyleGuide.hairlineBorderWidth
        dividerLabel.textColor = color
        dividerLabel.text = NSLocalizedString("Or", comment: "Divider on initial auth view separating auth options.").localizedUppercase
    }
    
    // MARK: - Button Actions
    
    @IBAction func handleSubmitButtonTapped(_ sender: UIButton) {
        // TODO: validateForm()
    }
    
    // MARK: - Table Management
    
    /// Registers all of the available TableViewCells.
    ///
    func registerTableViewCells() {
        let cells = [
            TextLabelTableViewCell.reuseIdentifier: TextLabelTableViewCell.loadNib(),
            TextFieldTableViewCell.reuseIdentifier: TextFieldTableViewCell.loadNib(),
            TextWithLinkTableViewCell.reuseIdentifier: TextWithLinkTableViewCell.loadNib()
        ]
        
        for (reuseIdentifier, nib) in cells {
            tableView.register(nib, forCellReuseIdentifier: reuseIdentifier)
        }
    }
    
    /// Describes how the tableView rows should be rendered.
    ///
    func loadRows() {
        rows = [.instructions, .email, .tos]
    }
    
    /// Configure cells.
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TextLabelTableViewCell:
            configureInstructionLabel(cell)
        case let cell as TextFieldTableViewCell:
            configureEmailField(cell)
        case let cell as TextWithLinkTableViewCell:
            configureTextWithLink(cell)
        default:
            DDLogError("Error: Unidentified tableViewCell type found.")
        }
    }
    
    /// Configure the instruction cell.
    ///
    func configureInstructionLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: WordPressAuthenticator.shared.displayStrings.getStartedInstructions)
    }
    
    /// Configure the textfield cell.
    ///
    func configureEmailField(_ cell: TextFieldTableViewCell) {
        cell.configureTextFieldStyle(with: .email,
                                     and: WordPressAuthenticator.shared.displayStrings.emailAddressPlaceholder)
    }
    
    /// Configure the link cell.
    ///
    func configureTextWithLink(_ cell: TextWithLinkTableViewCell) {
        cell.configureButton(markedText: WordPressAuthenticator.shared.displayStrings.loginTermsOfService)
        
        cell.actionHandler = { [weak self] in
            guard let self = self,
            let url = URL(string: WordPressAuthenticator.shared.configuration.wpcomTermsOfServiceURL) else {
                return
            }
            
            self.tracker.track(click: .termsOfService)

            let safariViewController = SFSafariViewController(url: url)
            safariViewController.modalPresentationStyle = .pageSheet
            self.present(safariViewController, animated: true, completion: nil)
        }
    }

    /// Rows listed in the order they were created.
    ///
    enum Row {
        case instructions
        case email
        case tos
        
        var reuseIdentifier: String {
            switch self {
            case .instructions:
                return TextLabelTableViewCell.reuseIdentifier
            case .email:
                return TextFieldTableViewCell.reuseIdentifier
            case .tos:
                return TextWithLinkTableViewCell.reuseIdentifier
                
            }
        }
    }
    
    enum Constants {
        static let footerFrame = CGRect(x: 0, y: 0, width: 0, height: 44)
        static let footerButtonInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
    
}

// MARK: - UITableViewDataSource

extension GetStartedViewController: UITableViewDataSource {
    
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
