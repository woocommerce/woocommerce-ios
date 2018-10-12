import UIKit

class PrivacySettingsViewController: UIViewController {

    /// Main TableView
    ///
    @IBOutlet weak var tableView: UITableView!

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureTableView()
    }
}

extension PrivacySettingsViewController {
    func configureNavigation() {
        title = NSLocalizedString("Privacy settings", comment: "Privacy settings screen title")
        // Don't show the Settings title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton
    }

    func configureMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    func configureTableView() {
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    private struct Constants {
        static let rowHeight = CGFloat(44)
    }

    private struct Section {
        let title: String?
        let rows: [Row]
    }

    private enum Row: CaseIterable {
        case trackingToggle
        case text
        case link

        var type: UITableViewCell.Type {
            switch self {
            case .trackingToggle:
                return BasicTableViewCell.self
            case .text:
                return BasicTableViewCell.self
            case .link:
                return BasicTableViewCell.self
            }
        }

        var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}
