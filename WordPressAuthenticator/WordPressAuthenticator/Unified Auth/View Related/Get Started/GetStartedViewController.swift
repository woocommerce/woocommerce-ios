import UIKit

class GetStartedViewController: LoginViewController {

    // MARK: - Properties
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?

    private var rows = [Row]()

    override open var sourceTag: WordPressSupportSourceTag {
        get {
            return .loginEmail
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavBar()
        setupTable()
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

// MARK: - Private methods

private extension GetStartedViewController {

    // MARK: - Configuration
    
    func configureNavBar() {
        navigationItem.title = WordPressAuthenticator.shared.displayStrings.getStartedTitle
        styleNavigationBar(forUnified: true)
        
        // Nav bar could be hidden from the host app, so reshow it.
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func setupTable() {
        defaultTableViewMargin = tableViewLeadingConstraint?.constant ?? 0
        setTableViewMargins(forWidth: view.frame.width)
    }

    // MARK: - Table Management
    
    /// Registers all of the available TableViewCells.
    ///
    func registerTableViewCells() {
        let cells = [
            TextLabelTableViewCell.reuseIdentifier: TextLabelTableViewCell.loadNib()
        ]
        
        for (reuseIdentifier, nib) in cells {
            tableView.register(nib, forCellReuseIdentifier: reuseIdentifier)
        }
    }
    
    /// Describes how the tableView rows should be rendered.
    ///
    func loadRows() {
        rows = [.instructions]
    }
    
    /// Configure cells.
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TextLabelTableViewCell where row == .instructions:
            configureInstructionLabel(cell)
        default:
            DDLogError("Error: Unidentified tableViewCell type found.")
        }
    }
    
    /// Configure the instruction cell.
    ///
    func configureInstructionLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: WordPressAuthenticator.shared.displayStrings.getStartedInstructions)
    }
    
    /// Rows listed in the order they were created.
    ///
    enum Row {
        case instructions
        
        var reuseIdentifier: String {
            switch self {
            case .instructions:
                return TextLabelTableViewCell.reuseIdentifier
            }
        }
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
