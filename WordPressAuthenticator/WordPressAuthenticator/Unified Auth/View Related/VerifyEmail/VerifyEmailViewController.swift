import UIKit

final class VerifyEmailViewController: LoginViewController {

    // MARK: Properties

    @IBOutlet private weak var tableView: UITableView!
    private let rows = Row.allCases

    override var sourceTag: WordPressSupportSourceTag {
        .verifyEmailInstructions
    }

    // MARK: - Actions
    @IBAction private func handleSendLinkButtonTapped(_ sender: NUXButton) {
        configureViewLoading(false)
        tracker.track(click: .requestMagicLink)
        requestAuthenticationLink()
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = WordPressAuthenticator.shared.displayStrings.logInTitle
        styleNavigationBar(forUnified: true)

        // Store default margin, and size table for the view.
        defaultTableViewMargin = tableViewLeadingConstraint?.constant ?? 0
        setTableViewMargins(forWidth: view.frame.width)

        localizePrimaryButton()
        registerTableViewCells()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isBeingPresentedInAnyWay {
            tracker.track(step: .verifyEmailInstructions)
        } else {
            tracker.set(step: .verifyEmailInstructions)
        }
    }

    // MARK: - Overrides

    /// Style individual ViewController backgrounds, for now.
    ///
    override func styleBackground() {
        guard let unifiedBackgroundColor = WordPressAuthenticator.shared.unifiedStyle?.viewControllerBackgroundColor else {
            super.styleBackground()
            return
        }

        view.backgroundColor = unifiedBackgroundColor
    }

    /// Style individual ViewController status bars.
    ///
    override var preferredStatusBarStyle: UIStatusBarStyle {
        WordPressAuthenticator.shared.unifiedStyle?.statusBarStyle ?? WordPressAuthenticator.shared.style.statusBarStyle
    }

    /// Override the title on 'Send link by Email' button
    ///
    override func localizePrimaryButton() {
        submitButton?.setTitle(WordPressAuthenticator.shared.displayStrings.magicLinkButtonTitle, for: .normal)
        submitButton?.accessibilityIdentifier = "Send Link by Email Button"
    }
}

// MARK: - UITableViewDataSource
extension VerifyEmailViewController: UITableViewDataSource {
    /// Returns the number of rows in a section.
    ///
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    /// Configure cells delegate method.
    ///
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - Private Methods
private extension VerifyEmailViewController {
    /// Registers all of the available TableViewCells.
    ///
    func registerTableViewCells() {
        let cells = [
            GravatarEmailTableViewCell.reuseIdentifier: GravatarEmailTableViewCell.loadNib(),
            TextLabelTableViewCell.reuseIdentifier: TextLabelTableViewCell.loadNib(),
            TextLinkButtonTableViewCell.reuseIdentifier: TextLinkButtonTableViewCell.loadNib()
        ]

        for (reuseIdentifier, nib) in cells {
            tableView.register(nib, forCellReuseIdentifier: reuseIdentifier)
        }
    }

    /// Configure cells.
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as GravatarEmailTableViewCell where row == .persona:
            configureGravatarEmail(cell)
        case let cell as TextLabelTableViewCell where row == .instructions:
            configureInstructionLabel(cell)
        case let cell as TextLinkButtonTableViewCell where row == .typePassword:
            configureTypePasswordButton(cell)
        default:
            DDLogError("Error: Unidentified tableViewCell type found.")
        }
    }

    /// Configure the gravatar + email cell.
    ///
    func configureGravatarEmail(_ cell: GravatarEmailTableViewCell) {
        cell.configure(withEmail: loginFields.username)
    }

    /// Configure the instructions cell.
    ///
    func configureInstructionLabel(_ cell: TextLabelTableViewCell) {
        let instructionColor = WordPressAuthenticator.shared.unifiedStyle?.textSubtleColor ?? WordPressAuthenticator.shared.style.subheadlineColor
        let emailColor = WordPressAuthenticator.shared.unifiedStyle?.textColor ?? WordPressAuthenticator.shared.style.instructionColor
        let font = WPStyleGuide.mediumWeightFont(forStyle: .body)

        let instructions = NSMutableAttributedString(string: WordPressAuthenticator.shared.displayStrings.verifyMailLoginInstructions, attributes: [.foregroundColor: instructionColor, .font: font])
        let email = NSAttributedString(string: " " + loginFields.username, attributes: [.font: font, .foregroundColor: emailColor])
        instructions.append(email)
        cell.configureLabel(attributedText: instructions)
    }

    /// Configure the "Or type your password" cell.
    ///
    func configureTypePasswordButton(_ cell: TextLinkButtonTableViewCell) {
        cell.configureButton(text: WordPressAuthenticator.shared.displayStrings.typePasswordButtonTitle)
    }

    /// Makes the call to request a magic authentication link be emailed to the user.
    ///
    func requestAuthenticationLink() {
        loginFields.meta.emailMagicLinkSource = .login

        let email = loginFields.username

        configureViewLoading(true)
        let service = WordPressComAccountService()
        service.requestAuthenticationLink(for: email,
                                          jetpackLogin: loginFields.meta.jetpackLogin,
                                          success: { [weak self] in
                                            self?.didRequestAuthenticationLink()
                                            self?.configureViewLoading(false)

            }, failure: { [weak self] (error: Error) in
                guard let self = self else { return }

                self.tracker.track(failure: error.localizedDescription)

                self.displayError(error as NSError, sourceTag: self.sourceTag)
                self.configureViewLoading(false)
        })
    }

    /// When a magic link successfully sends, navigate the user to the next step.
    ///
    func didRequestAuthenticationLink() {
        guard let vc = LoginMagicLinkViewController.instantiate(from: .unifiedLoginMagicLink) else {
            DDLogError("Failed to navigate to LoginMagicLinkViewController from VerifyEmailViewController")
            return
        }

        vc.loginFields = loginFields
        vc.loginFields.restrictToWPCom = true
        navigationController?.pushViewController(vc, animated: true)
    }

    /// Presents unified password screen
    ///
    func presentUnifiedPassword() {
        guard let vc = PasswordViewController.instantiate(from: .password) else {
            DDLogError("Failed to navigate to PasswordViewController from VerifyEmailViewController")
            return
        }
        vc.loginFields = loginFields
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Private Constants

    /// Rows listed in the order they were created.
    ///
    enum Row: CaseIterable {
        case persona
        case instructions
        case typePassword

        var reuseIdentifier: String {
            switch self {
            case .persona:
                return GravatarEmailTableViewCell.reuseIdentifier
            case .instructions:
                return TextLabelTableViewCell.reuseIdentifier
            case .typePassword:
                return TextLinkButtonTableViewCell.reuseIdentifier
            }
        }
    }
}
