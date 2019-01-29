import UIKit
import CocoaLumberjack


// MARK: - ApplicationLogViewController
//
class ApplicationLogViewController: UIViewController {

    /// Main TableView
    ///
    @IBOutlet weak var tableView: UITableView!

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()

    /// Access the shared DDFileLogger
    ///
    let fileLogger = AppDelegate.shared.fileLogger

    /// List of log files
    ///
    var logFiles = [DDLogFileInfo]()

    /// Date formatter
    ///
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.doesRelativeDateFormatting = true
        formatter.timeStyle = .short

        return formatter
    }()


    // MARK: - Overridden Methods
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureTableView()

        loadLogFiles()

        configureSections()
        registerTableViewCells()
    }

    /// Style the back button, add the title to nav bar.
    ///
    func configureNavigation() {
        title = NSLocalizedString("Activity Logs", comment: "Activity Log navigation bar title")

        // Don't show the Help & Support title in the next-view's back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)
    }

    /// Apply Woo styles.
    ///
    func configureMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    /// Configure common table properties.
    ///
    func configureTableView() {
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    /// Get the sorted log files
    ///
    func loadLogFiles() {
        logFiles = fileLogger.logFileManager.sortedLogFileInfos
    }

    /// Define section data.
    ///
    func configureSections() {
        let logFileTitle = NSLocalizedString("Log files by created date", comment: "Explains that the files are sorted by LIFO date: most recent day listed first.")
        let logFileFooter = NSLocalizedString("Up to seven days՚ worth of logs are saved.", comment: "Footer text below the list of logs explaining the maximum number of logs saved.")

        var logFileRows = [Row]()
        for _ in logFiles {
            logFileRows.append(.logFile)
        }

        sections = [
            Section(title: logFileTitle, footer: logFileFooter, rows: logFileRows),
            Section(title: nil, footer:nil, rows:[.clearLogs])
        ]
    }

    /// Register table cells.
    ///
    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension ApplicationLogViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension ApplicationLogViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rowAtIndexPath(indexPath) {
        case .logFile:
            logFileWasPressed()
        case .clearLogs:
            clearLogsWasPressed()
        }
    }
}

// MARK: - View Configuration
//
private extension ApplicationLogViewController {
    /// Convenience method returns a single row's data
    ///
    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as BasicTableViewCell where row == .logFile:
            configureLogFile(cell: cell, indexPath: indexPath)
        case let cell as BasicTableViewCell where row == .clearLogs:
            configureClearLogs(cell: cell)
        default:
            fatalError()
        }
    }

    /// Application Log cell.
    ///
    func configureLogFile(cell: BasicTableViewCell, indexPath: IndexPath) {
        let logFileInfo: DDLogFileInfo = logFiles[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = indexPath.row == 0 ? NSLocalizedString("Current", comment:"Cell title: the current date.") : dateFormatter.string(from: logFileInfo.creationDate)
        print(logFileInfo.creationDate)
        print(dateFormatter.string(from: logFileInfo.creationDate))
    }

    /// Clear application logs cell.
    ///
    func configureClearLogs(cell: BasicTableViewCell) {
        cell.selectionStyle = .default
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = StyleManager.destructiveActionColor
        cell.textLabel?.text = NSLocalizedString("Clear old activity logs", comment: "Deletes all activity logs except for the marked 'Current'.")
    }
}

// MARK: - Actions
//
private extension ApplicationLogViewController {

    /// View log file action
    ///
    func logFileWasPressed() {

    }

    /// Clear old logs action
    ///
    func clearLogsWasPressed() {

    }
}


// MARK: - Private types
//
private struct Constants {
    static let rowHeight = CGFloat(44)
}

private struct Section {
    let title: String?
    let footer: String?
    let rows: [Row]
}

private enum Row: CaseIterable {
    case logFile
    case clearLogs

    var type: UITableViewCell.Type {
        switch self {
        case .logFile:
            return BasicTableViewCell.self
        case .clearLogs:
            return BasicTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}
