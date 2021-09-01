import UIKit

final class SeveralReadersFoundViewController: UIViewController, UITableViewDelegate {

    @IBOutlet weak var headlineLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cancelButton: UIButton!

    private var sections = [Section]()

    private var readerIDs = [String]()

    // TODO - handle orientation changes

    init() {
        super.init(nibName: Self.nibName, bundle: nil)

        modalPresentationStyle = .overFullScreen

        // Dummy data for now
        self.readerIDs = [
            "CHB204909005931",
            "CHB204909005942",
            "CHB204909005953",
            "CHB204909005964",
        ]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        registerTableViewCells()
        configureNavigation()
        configureSections()
        configureTable()
    }

    // TODO - accept updates to the list of CardReaderIDs to present and reloadData

    // TODO - call completion with selected CardReaderID? (nil on cancel)
}

// MARK: - View Configuration
//
private extension SeveralReadersFoundViewController {
    /// Set the title and back button.
    ///
    func configureNavigation() {
        headlineLabel.text = Localization.headline
        cancelButton.setTitle(Localization.cancel, for: .normal)
    }

    /// Setup the sections in this table view
    ///
    func configureSections() {
        sections = []

        // Prepare a row for each reader
        let readerRows = readerIDs.map { Row.reader($0) }

        sections.append(
            Section(rows: readerRows)
        )

        sections.append(
            Section(rows: [.scanning])
        )
    }

    func configureTable() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }

    /// Register table cells.
    ///
    func registerTableViewCells() {
        tableView.registerNib(for: Row.reader("").type)
        tableView.registerNib(for: Row.scanning.type)
    }

    /// Configure the cell being set up for the given row by `cellForRowAt`
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch row {
        case .reader(let readerID):
            configureReaderRow(cell: cell, readerID: readerID)
        case .scanning:
            configureScanningRow(cell: cell)
        }
    }

    private func configureReaderRow(cell: UITableViewCell, readerID: String) {
        guard let cell = cell as? LabelAndButtonTableViewCell else {
            return
        }
        cell.label.text = readerID
        cell.button.setTitle(Localization.connect, for: .normal)
        cell.selectionStyle = .none
    }

    private func configureScanningRow(cell: UITableViewCell) {
        guard let cell = cell as? ActivitySpinnerAndLabelTableViewCell else {
            return
        }
        cell.label.text = Localization.scanningLabel
        cell.selectionStyle = .none
    }
}

// MARK: - Convenience Methods
//
private extension SeveralReadersFoundViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension SeveralReadersFoundViewController: UITableViewDataSource {
    /// Always two sections. The first contains a cell for each found reader. The second
    /// contains a single cell showing scanning in progress.
    ///
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
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
private struct Section {
    let rows: [Row]
}

private enum Row {
    /// Two or more `.reader` rows have their reader IDs as their associated (String) value
    /// and are used to display the reader IDs and their connect buttons
    ///
    case reader(String)

    /// A single `.scanning` row is used to show that we are actively scanning for
    /// more readers
    ///
    case scanning

    var type: UITableViewCell.Type {
        switch self {
        case .reader:
            return LabelAndButtonTableViewCell.self
        case .scanning:
            return ActivitySpinnerAndLabelTableViewCell.self
        }
    }

    var height: CGFloat {
        return UITableView.automaticDimension
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}

// MARK: - Localization
//
private extension SeveralReadersFoundViewController {
    enum Localization {
        static let headline = NSLocalizedString(
            "Several readers found",
            comment: "Title of a modal presenting a list of readers to choose from."
        )

        static let connect = NSLocalizedString(
            "Connect",
            comment: "Button in a cell to allow the user to connect to that reader for that cell"
        )

        static let scanningLabel = NSLocalizedString(
            "Scanning for readers",
            comment: "Label for a cell informing the user that reader scanning is ongoing."
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to allow the user to close the modal without connecting."
        )
    }
}
