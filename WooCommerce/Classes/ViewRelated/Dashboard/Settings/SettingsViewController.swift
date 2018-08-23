import UIKit
import Yosemite


// MARK: - SettingsViewController
//
class SettingsViewController: UIViewController {

    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!

    private var sections = [Section]()
    private var accountName: String = ""
    private var siteUrl: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Settings", comment: "Settings navigation title")
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor

        configureAccount()
        configureTableView()
    }

    func configureAccount() {
        if let account = StoresManager.shared.sessionManager.defaultAccount {
            accountName = account.displayName
        }

        if let site = StoresManager.shared.sessionManager.defaultSite {
            let baseString = site.url
            let baseUrl = NSURL(string: baseString)
            if let scheme = baseUrl?.scheme {
                // remove `https://` or `http://` from the site url
                let host = scheme + "://"
                siteUrl = baseString.replacingOccurrences(of: host, with: "")
            }
        }
    }

    func configureTableView() {
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        // `tableView.tableFooterView` can't handle a footerView that uses
        // autolayout only. Hence the container view with a defined frame.
        let footerContainer = UIView(frame: CGRect(x: 0, y: 0, width: Int(self.tableView.frame.width), height: Constants.footerHeight))
        let footerView = SettingsFooterView.makeFromNib()
        self.tableView.tableFooterView = footerContainer
        footerContainer.addSubview(footerView)

        let primaryStoreSection = Section(title: NSLocalizedString("PRIMARY STORE", comment: "My Store > Settings > Primary Store information section"), rows: [.primaryStore])
        let logoutSection = Section(title: nil, rows: [.logout])
        sections = [primaryStoreSection, logoutSection]

        configureNibs()
    }

    func configureNibs() {
        for section in sections {
            for row in section.rows {
                let nib = UINib(nibName: row.reuseIdentifier, bundle: nil)
                tableView.register(nib, forCellReuseIdentifier: row.reuseIdentifier)
            }
        }
    }

    func handleLogout() {
        let name = String(format: NSLocalizedString("Are you sure you want to log out of the account %@?", comment: "Alert message to confirm a user meant to log out."), accountName)
        let alertController = UIAlertController(title: "", message: name, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: NSLocalizedString("Back", comment: "Alert button title - dismisses alert, which cancels the log out attempt"), style: .cancel)
        alertController.addAction(cancelAction)

        let logOutAction = UIAlertAction(title: NSLocalizedString("Log Out", comment: "Alert button title - confirms and logs out the user"), style: .default) { (action) in
            self.logOutUser()
        }
        alertController.addAction(logOutAction)

        alertController.preferredAction = logOutAction
        present(alertController, animated: true)
    }

    func logOutUser() {
        WooAnalytics.shared.track(.logout)
        StoresManager.shared.deauthenticate()
        navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // iOS 11 table bug. Must return a tiny value to collapse `nil` or `empty` section headers.
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
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
extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Cell Configuration
//
extension SettingsViewController {
    private func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as HeadlineLabelTableViewCell:
            cell.headline = siteUrl
            cell.body = accountName
        case let cell as LogOutTableViewCell:
            cell.didSelectLogout = { [weak self] in
                self?.handleLogout()
            }
        default:
            fatalError("Unidentified Settings row type")
        }
    }

    // MARK: - Constants
    //
    struct Constants {
        static let rowHeight = CGFloat(44)
        static let footerHeight = 90
    }

    private struct Section {
        let title: String?
        let rows: [Row]
    }

    private enum Row {
        case primaryStore
        case logout

        var reuseIdentifier: String {
            switch self {
            case .primaryStore:
                return HeadlineLabelTableViewCell.reuseIdentifier
            case .logout:
                return LogOutTableViewCell.reuseIdentifier
            }
        }
    }
}
