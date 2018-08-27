import UIKit
import Yosemite


// MARK: - SettingsViewController
//
class SettingsViewController: UIViewController {

    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!

    private var sections = [Section]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Settings", comment: "Settings navigation title")
        view.backgroundColor = StyleManager.sectionBackgroundColor
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
        configureTableView()
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

        let logoutSection = Section(title: nil, rows: [.logout])
        sections = [logoutSection]

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
        var accountName: String = ""
        if let account = StoresManager.shared.sessionManager.defaultAccount {
            accountName = account.displayName
        }

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
        if sections[section].title == nil {
            // iOS 11 table bug. Must return a tiny value to collapse `nil` or `empty` section headers.
            return CGFloat.leastNonzeroMagnitude
        }

        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // iOS 11 table bug. Must return a tiny value to collapse `nil` or `empty` section footers.
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        if let logoutCell = cell as? LogOutTableViewCell {
            logoutCell.didSelectLogout = { [weak self] in
                self?.handleLogout()
            }
        }

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

// MARK: - Constants
//
private extension SettingsViewController {
    struct Constants {
        static let rowHeight = CGFloat(44)
        static let footerHeight = 90
    }

    private struct Section {
        let title: String?
        let rows: [Row]
    }

    private enum Row {
        case logout

        var reuseIdentifier: String {
            switch self {
            case .logout:
                return LogOutTableViewCell.reuseIdentifier
            }
        }
    }
}
