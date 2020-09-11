import UIKit
import WordPressShared
import SafariServices
import AutomatticTracks

class AboutViewController: UIViewController {

    /// Main TableView
    ///
    @IBOutlet weak private var tableView: UITableView!

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()

    /// Footer Text String
    ///
    private lazy var footerTitleText: String = {
        let year = Calendar.current.component(.year, from: Date()).description
        let localizedTitleTextLine1 = String.localizedStringWithFormat(
            NSLocalizedString("Version %@", comment: "Displays the version of the App"),
            Bundle.main.detailedVersionNumber()
        )
        let localizedTitleTextLine2 = String.localizedStringWithFormat(
            NSLocalizedString("© %@ Automattic, Inc.", comment: "About View's Footer Text. The variable is the current year"),
            year
        )
        return String(format: localizedTitleTextLine1, year) + "\n" + localizedTitleTextLine2
    }()


    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureSections()
        configureTableView()
        configureTableViewHeader()
        configureTableViewFooter()
        registerTableViewCells()
    }

    /// Manage device rotation
    ///
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        configureTableViewInsets()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.updateFooterHeight()
    }
}


// MARK: - View Configuration
//
private extension AboutViewController {

    /// Set the title and back button.
    ///
    func configureNavigation() {
        title = NSLocalizedString("About", comment: "About this app (information page title)")
        // Don't show the About title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton
    }

    /// Apply Woo styles.
    ///
    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    /// Configure common table properties.
    ///
    func configureTableView() {
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground
        configureTableViewInsets()
    }

    func configureTableViewInsets() {
        guard let tabBarHeight = tabBarController?.tabBar.frame.height else {
            return
        }
        let adjustForTabbarInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: tabBarHeight, right: 0)
        tableView.contentInset = adjustForTabbarInsets
        tableView.scrollIndicatorInsets = adjustForTabbarInsets
    }

    /// Setup the tableview header.
    ///
    func configureTableViewHeader() {
        let tintedImage             = UIImage.wooLogoImage(withSize: Constants.headerImageSize, tintColor: .primary)
        let imageView               = UIImageView(image: tintedImage)
        imageView.contentMode       = .center
        imageView.frame.size.height += Constants.headerPadding
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(crashDebugMenuGestureRecognizer)
        tableView.tableHeaderView = imageView
    }

    /// Setup the tableview footer.
    ///
    func configureTableViewFooter() {
        /// `tableView.tableFooterView` can't handle a footerView that uses autolayout only.
        /// Hence the container view with a defined frame.
        let footerContainer = UIView(frame: CGRect(x: 0, y: 0, width: Int(tableView.frame.width), height: Constants.footerHeight))
        let footerView = TableFooterView.instantiateFromNib() as TableFooterView
        footerView.footnote.attributedText = nil
        footerView.footnote.text = footerTitleText
        footerView.footnote.textColor = .textSubtle
        tableView.tableFooterView = footerContainer
        footerContainer.addSubview(footerView)
    }

    /// Setup the sections in this table view
    ///
    func configureSections() {
        sections = [Section(title: nil, rows: [.terms, .privacy, .californiaPrivacy])]
    }

    /// Register table cells.
    ///
    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }

    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as BasicTableViewCell where row == .californiaPrivacy:
            configureCaliforniaPrivacy(cell: cell)
        case let cell as BasicTableViewCell where row == .terms:
            configureTerms(cell: cell)
        case let cell as BasicTableViewCell where row == .privacy:
            configurePrivacy(cell: cell)
        default:
            fatalError()
        }
    }

    /// Terms of service cell.
    ///
    func configureTerms(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Terms of Service", comment: "Opens the Terms of Service web page")
    }

    /// Privacy policy cell.
    ///
    func configurePrivacy(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Privacy Policy", comment: "Opens the Privacy Policy web page")
    }

    /// California Privacy policy cell.
    ///
    func configureCaliforniaPrivacy(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Privacy Notice for California Users", comment: "Opens the California Privacy Policy web page")
    }
}


// MARK: - Convenience Methods
//
private extension AboutViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    func displayWebView(url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }
}


// MARK: - Actions
//
private extension AboutViewController {

    /// California Privacy Policy action
    ///
    func californiaPrivacyWasPressed() {
        displayWebView(url: WooConstants.URLs.californiaPrivacy.asURL())
    }

    /// Privacy Policy action
    ///
    func privacyWasPressed() {
        displayWebView(url: WooConstants.URLs.privacy.asURL())
    }

    /// Terms of Service action
    ///
    func termsWasPressed() {
        displayWebView(url: WooConstants.URLs.termsOfService.asURL())
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension AboutViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension AboutViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rowAtIndexPath(indexPath) {
        case .californiaPrivacy:
            californiaPrivacyWasPressed()
        case .privacy:
            privacyWasPressed()
        case .terms:
            termsWasPressed()
        }
    }
}

// MARK: - Crash Debug Menu
//
extension AboutViewController {

    private var crashDebugMenuGestureRecognizer: UITapGestureRecognizer {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didInvokeCrashDebugMenu))
        gestureRecognizer.numberOfTapsRequired = 4
        return gestureRecognizer
    }

    @objc func didInvokeCrashDebugMenu(_ sender: UITapGestureRecognizer? = nil) {

        let menuTitle = NSLocalizedString(
            "Crash Debug Menu",
            comment: "The title for a menu that helps debug crashes in production builds"
        )

        let crashDebugMenu = UIAlertController(title: menuTitle, message: nil, preferredStyle: .actionSheet)
        crashDebugMenu.addAction(crashDebugMenuCrashAction)
        crashDebugMenu.addAction(crashDebugMenuCancelAction)

        present(crashDebugMenu, animated: true, completion: nil)
    }

    private var crashDebugMenuCrashAction: UIAlertAction {
        let crashTitle = NSLocalizedString(
            "Crash Immediately",
            comment: "The title for a button that causes the app to deliberately crash for debugging purposes"
        )

        return UIAlertAction(title: crashTitle, style: .destructive) { _ in
            CrashLogging.crash()
        }
    }

    private var crashDebugMenuCancelAction: UIAlertAction {
        let cancelTitle = NSLocalizedString(
            "Cancel",
            comment: "The title for a button that dismisses the crash debug menu"
        )
        return UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
    }
}

// MARK: - Private Types
//
private struct Constants {
    static let rowHeight       = CGFloat(44)
    static let headerImageSize = CGSize(width: 61, height: 36)
    static let headerPadding   = CGFloat(60)
    static let footerHeight    = 44
}

private struct Section {
    let title: String?
    let rows: [Row]
}

private enum Row: CaseIterable {
    case terms
    case privacy
    case californiaPrivacy

    var type: UITableViewCell.Type {
        switch self {
        case .californiaPrivacy:
            return BasicTableViewCell.self
        case .terms:
            return BasicTableViewCell.self
        case .privacy:
            return BasicTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}
