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
    let fileLogger = ServiceLocator.fileLogger

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
        title = NSLocalizedString(
            "Application Logs",
            comment: "Application Logs navigation bar title - this screen is where users view the list of application logs available to them."
        )
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
    }

    /// Get the sorted log files
    ///
    func loadLogFiles() {
        logFiles = fileLogger.logFileManager.sortedLogFileInfos
    }

    /// Define section data.
    ///
    func configureSections() {
        let logFileTitle = NSLocalizedString(
            "Log files by created date",
            comment: "Explains that the files are sorted by LIFO date: most recent day listed first."
        )
        let logFileFooter = NSLocalizedString(
            "Up to seven days՚ worth of logs are saved.",
            comment: "Footer text below the list of logs explaining the maximum number of logs saved."
        )

        var logFileRows = [Row]()
        for _ in logFiles {
            logFileRows.append(.logFile)
        }

        sections = [
            Section(title: logFileTitle, footer: logFileFooter, rows: logFileRows),
            Section(title: nil, footer: nil, rows: [.clearLogs])
        ]
    }

    /// Register table cells.
    ///
    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
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
            logFileWasPressed(in: indexPath.row)
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
        cell.textLabel?.text = indexPath.row == 0 ?
            NSLocalizedString("Current", comment: "Cell title: the current date.") : dateFormatter.string(from: logFileInfo.creationDate )
    }

    /// Clear application logs cell.
    ///
    func configureClearLogs(cell: BasicTableViewCell) {
        cell.selectionStyle = .default
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .error
        cell.textLabel?.text = NSLocalizedString("Reset Activity Log", comment: "Deletes all activity logs except for the marked 'Current'.")
    }
}

// MARK: - Actions
//
private extension ApplicationLogViewController {

    /// View log file action
    ///
    func logFileWasPressed(in row: Int) {
        let logFileInfo = logFiles[row]

        let identifier = ApplicationLogDetailViewController.classNameWithoutNamespaces
        guard let appLogDetailVC = UIStoryboard.dashboard.instantiateViewController(identifier: identifier) as? ApplicationLogDetailViewController else {
            DDLogError("Error: attempted to instantiate ApplicationLogDetailViewController. Instantiation failed.")
            return
        }
        do {
            let contents = try String(contentsOfFile: logFileInfo.filePath)
            let date = dateFormatter.string(from: logFileInfo.creationDate )
            appLogDetailVC.logText = contents
            appLogDetailVC.logDate = date
        } catch {
            DDLogError("Error: attempted to get contents of logFileInfo. Contents not found.")
        }
        navigationController?.pushViewController(appLogDetailVC, animated: true)
    }

    /// Clear old logs action
    ///
    func clearLogsWasPressed() {
        for logFileInfo in logFiles where logFileInfo.isArchived {
            try? FileManager.default.removeItem(atPath: logFileInfo.filePath)
        }

        DDLogWarn("⚠️ All archived log files erased.")

        loadLogFiles()
        configureSections()
        tableView.reloadData()
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
