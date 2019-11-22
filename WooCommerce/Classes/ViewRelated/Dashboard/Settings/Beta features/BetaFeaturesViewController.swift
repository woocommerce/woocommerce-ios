import Storage
import UIKit
import Yosemite

/// Contains UI for Beta features that can be turned on and off.
///
class BetaFeaturesViewController: UIViewController {

    /// Main TableView
    ///
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        return tableView
    }()

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()

    private let siteID: Int

    init(siteID: Int) {
        self.siteID = siteID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overridden Methods
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureMainView()
        configureSections()
        configureTableView()
        registerTableViewCells()
    }
}

// MARK: - View Configuration
//
private extension BetaFeaturesViewController {

    /// Set the title.
    ///
    func configureNavigationBar() {
        title = NSLocalizedString("Experimental Features", comment: "Beta features navigation title")
    }

    /// Apply Woo styles.
    ///
    func configureMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    /// Configure common table properties.
    ///
    func configureTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(tableView)

        tableView.dataSource = self

        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    /// Configure sections for table view.
    ///
    func configureSections() {
        sections = [
            Section(rows: [.statsVersionSwitch,
                           .statsVersionDescription])
        ]
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
        guard type(of: cell) == row.type else {
            assertionFailure("The type of cell (\(type(of: cell)) does not match the type (\(row.type)) for row: \(row)")
            return
        }

        switch cell {
        case let cell as SwitchTableViewCell where row == .statsVersionSwitch:
            configureStatsVersionSwitch(cell: cell)
        case let cell as BasicTableViewCell where row == .statsVersionDescription:
            configureStatsVersionDescription(cell: cell)
        default:
            fatalError()
        }
    }

    // MARK: - Stats version feature

    func configureStatsVersionSwitch(cell: SwitchTableViewCell) {
        cell.accessoryType = .none
        cell.selectionStyle = .none
        let statsVersionTitle = NSLocalizedString("Improved stats",
                                                  comment: "My Store > Settings > Beta features > Switch stats version")
        cell.title = statsVersionTitle

        let action = AppSettingsAction.loadInitialStatsVersionToShow(siteID: siteID) { initialStatsVersion in
            cell.isOn = initialStatsVersion == .v4
        }
        ServiceLocator.stores.dispatch(action)

        cell.onChange = { [weak self] isSwitchOn in
            guard let siteID = self?.siteID else {
                return
            }
            ServiceLocator.analytics.track(.settingsBetaFeaturesNewStatsUIToggled)

            let statsVersion: StatsVersion = isSwitchOn ? .v4: .v3
            let action = AppSettingsAction.setStatsVersionPreference(siteID: siteID,
                                                                     statsVersion: statsVersion)
            ServiceLocator.stores.dispatch(action)
        }
    }

    func configureStatsVersionDescription(cell: BasicTableViewCell) {
        cell.accessoryType = .none
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = NSLocalizedString("Try the new stats available with the WooCommerce Admin plugin",
                                                 comment: "My Store > Settings > Beta features > Stats version description")
    }
}


// MARK: - Convenience Methods
//
private extension BetaFeaturesViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension BetaFeaturesViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

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
    let rows: [Row]
}

private enum Row: CaseIterable {
    case statsVersionSwitch
    case statsVersionDescription

    var type: UITableViewCell.Type {
        switch self {
        case .statsVersionSwitch:
            return SwitchTableViewCell.self
        case .statsVersionDescription:
            return BasicTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}
