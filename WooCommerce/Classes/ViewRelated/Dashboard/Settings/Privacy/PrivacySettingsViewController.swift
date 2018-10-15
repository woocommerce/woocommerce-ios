import UIKit
import Gridicons

class PrivacySettingsViewController: UIViewController {

    /// Main TableView
    ///
    @IBOutlet weak var tableView: UITableView!

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()

    // MARK: - Overridden Methods
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureTableView()
        configureSections()
        registerTableViewCells()
    }
}


// MARK: - View Configuration
//
private extension PrivacySettingsViewController {

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

    func configureSections() {
        sections = [
            Section(title: nil, rows: [.collectInfo, .shareInfo, .cookiePolicy]),
//            Section(title: nil, rows: [.privacyInfo, .privacyPolicy]),
//            Section(title: nil, rows: [.cookieInfo, .cookiePolicy]),
        ]
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }

    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as BasicTableViewCell where row == .collectInfo:
            cell.imageView?.image = Gridicon.iconOfType(.stats)
            cell.imageView?.tintColor = StyleManager.defaultTextColor
            cell.textLabel?.text = NSLocalizedString("Collect information", comment: "Label for collecting analytics information toggle")

            // create a switch
            let collectInfoSwitch = UISwitch()
            //TODO: pull current tracking settings

            // set switch to on / off
            collectInfoSwitch.setOn(true, animated: false)
            // add to accessory view
            cell.accessoryView?.addSubview(collectInfoSwitch)
        case let cell as BasicTableViewCell where row == .shareInfo:
            cell.imageView?.image = Gridicon.iconOfType(.infoOutline)
            cell.imageView?.tintColor = StyleManager.defaultTextColor
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = NSLocalizedString("Share information with our analytics tool about your use of services while logged in to your WordPress.com account", comment: "Explains what the 'collect information' toggle is collecting")
        case let cell as BasicTableViewCell where row == .cookiePolicy:
            // To align the 'Learn more' cell to the others, add an invisible image.
            cell.imageView?.image = Gridicon.iconOfType(.image)
            cell.imageView?.tintColor = .white

            cell.textLabel?.text = NSLocalizedString("Learn more", comment: "Learn more text link")
            cell.textLabel?.textColor = StyleManager.wooCommerceBrandColor
        default:
            fatalError()
        }
    }
}

// MARK: - Convenience Methods
//
private extension PrivacySettingsViewController {
    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension PrivacySettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}


// MARK: - Private Types
//
private struct Constants {
    static let rowHeight = CGFloat(44)
}

private struct Section {
    let title: String?
    let rows: [Row]
}

private enum Row: CaseIterable {
    case collectInfo
    case cookieInfo
    case cookiePolicy
    case privacyInfo
    case privacyPolicy
    case shareInfo

    var type: UITableViewCell.Type {
        switch self {
        case .collectInfo:
            return BasicTableViewCell.self
        case .cookieInfo:
            return BasicTableViewCell.self
        case .cookiePolicy:
            return BasicTableViewCell.self
        case .privacyInfo:
            return BasicTableViewCell.self
        case .privacyPolicy:
            return BasicTableViewCell.self
        case .shareInfo:
            return BasicTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}
