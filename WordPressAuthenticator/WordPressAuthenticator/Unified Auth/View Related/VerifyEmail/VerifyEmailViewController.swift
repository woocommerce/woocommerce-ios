import UIKit

final class VerifyEmailViewController: LoginViewController {

    // MARK: Properties

    @IBOutlet private weak var tableView: UITableView!

    private let rows = Row.allCases

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
