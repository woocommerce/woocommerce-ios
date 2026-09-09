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

    /// The temporary archive must remain available until the share sheet finishes using it.
    ///
    private var exportedLogsURL: URL?

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
            Section(title: nil, footer: nil, rows: [.exportAllLogs]),
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
        case .exportAllLogs:
            exportAllLogs(from: tableView.cellForRow(at: indexPath))
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
        case let cell as BasicTableViewCell where row == .exportAllLogs:
            configureExportAllLogs(cell: cell)
        case let cell as BasicTableViewCell where row == .logFile:
            configureLogFile(cell: cell, indexPath: indexPath)
        case let cell as BasicTableViewCell where row == .clearLogs:
            configureClearLogs(cell: cell)
        default:
            fatalError()
        }
    }

    /// Export all application logs cell.
    ///
    func configureExportAllLogs(cell: BasicTableViewCell) {
        cell.selectionStyle = .default
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .accent
        cell.textLabel?.text = Localization.exportAllLogs
    }

    /// Application Log cell.
    ///
    func configureLogFile(cell: BasicTableViewCell, indexPath: IndexPath) {
        let logFileInfo: DDLogFileInfo = logFiles[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = indexPath.row == 0 ?
            NSLocalizedString("Current", comment: "Cell title: the current date.") : dateFormatter.string(from: logFileInfo.creationDate ?? Date())
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

    /// Creates and shares a ZIP archive containing every retained log file.
    ///
    func exportAllLogs(from sourceView: UIView?) {
        removeExportedLogs()
        setExportInProgress(true, in: sourceView)

        let logFileURLs = fileLogger.logFileManager.sortedLogFileInfos.map { URL(fileURLWithPath: $0.filePath) }
        Task { [weak self, weak sourceView] in
            guard let self else {
                return
            }
            defer { setExportInProgress(false, in: sourceView) }

            do {
                let archiveURL = try await Task.detached(priority: .userInitiated) {
                    try ApplicationLogsExporter().export(logFileURLs: logFileURLs)
                }.value
                exportedLogsURL = archiveURL

                let activityViewController = UIActivityViewController(activityItems: [archiveURL], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = sourceView ?? view
                activityViewController.popoverPresentationController?.sourceRect = sourceView?.bounds ?? view.bounds
                activityViewController.completionWithItemsHandler = { [weak self] _, _, _, _ in
                    self?.removeExportedLogs()
                }
                present(activityViewController, animated: true)
            } catch {
                DDLogError("⛔️ Error exporting application logs: \(error)")
                presentExportError()
            }
        }
    }

    func removeExportedLogs() {
        guard let exportedLogsURL else {
            return
        }
        do {
            try FileManager.default.removeItem(at: exportedLogsURL.deletingLastPathComponent())
        } catch {
            DDLogError("⛔️ Error removing exported application logs: \(error)")
        }
        self.exportedLogsURL = nil
    }

    func setExportInProgress(_ isExporting: Bool, in sourceView: UIView?) {
        sourceView?.isUserInteractionEnabled = !isExporting

        guard let cell = sourceView as? UITableViewCell else {
            return
        }
        if isExporting {
            let indicator = UIActivityIndicatorView(style: .medium)
            indicator.startAnimating()
            cell.accessoryView = indicator
        } else {
            cell.accessoryView = nil
        }
    }

    func presentExportError() {
        let alert = UIAlertController(title: Localization.exportErrorTitle, message: Localization.exportErrorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localization.ok, style: .default))
        present(alert, animated: true)
    }

    /// View log file action
    ///
    func logFileWasPressed(in row: Int) {
        let logFileInfo = logFiles[row]

        do {
            let contents = try String(contentsOfFile: logFileInfo.filePath, encoding: .utf8)
            let date = dateFormatter.string(from: logFileInfo.creationDate ?? Date())
            let viewModel = ApplicationLogViewModel(logText: contents, logDate: date)
            let appLogDetailVC = ApplicationLogDetailViewController(viewModel: viewModel)
            show(appLogDetailVC, sender: self)
        } catch {
            DDLogError("Error: attempted to get contents of logFileInfo. Contents not found.")
        }
    }

    /// Clear old logs action
    ///
    func clearLogsWasPressed() {
        for logFileInfo in logFiles {
            do {
                try FileManager.default.removeItem(atPath: logFileInfo.filePath)
            } catch {
                DDLogError("⚠️ Error deleting log files \(error)")
            }
        }

        DDLogWarn("⚠️ All log files erased.")

        navigationController?.popViewController(animated: true)
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
    case exportAllLogs
    case logFile
    case clearLogs

    var type: UITableViewCell.Type {
        switch self {
        case .exportAllLogs:
            return BasicTableViewCell.self
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

private extension ApplicationLogViewController {
    enum Localization {
        static let exportAllLogs = NSLocalizedString(
            "applicationLog.exportAllLogs",
            value: "Export All Logs",
            comment: "Button that exports all retained application logs as a ZIP file."
        )
        static let exportErrorTitle = NSLocalizedString(
            "applicationLog.exportError.title",
            value: "Unable to Export Logs",
            comment: "Title of an alert shown when application logs could not be exported."
        )
        static let exportErrorMessage = NSLocalizedString(
            "applicationLog.exportError.message",
            value: "Please try again.",
            comment: "Message of an alert shown when application logs could not be exported."
        )
        static let ok = NSLocalizedString(
            "applicationLog.exportError.ok",
            value: "OK",
            comment: "Button that dismisses the application log export error alert."
        )
    }
}
