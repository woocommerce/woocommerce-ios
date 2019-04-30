import UIKit
import Yosemite

// MARK: - CustomDateRangeSelectionViewController
//
class CustomDateRangeSelectionViewController: UIViewController {

    /// Closure to be executed when the user taps on Apply
    ///
    var onSelectionCompleted: ((_ startDate: Date, _ endDate: Date) -> Void)?

    /// Main TableView
    ///
    @IBOutlet weak var tableView: UITableView!

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()

    /// Start date for the range
    ///
    private var startDate: Date

    /// End date for the range
    ///
    private var endDate: Date

    /// Parent row for the date picker (above it visually)
    ///
    private var datePickerParentRow: Row?

    // MARK: - Computed Properties

    private var datePickerDate: Date {
        switch datePickerParentRow {
        case .some(.rangeStart):
            return startDate
        case .some(.rangeEnd):
            return endDate
        default:
            return Date()
        }
    }

    // MARK: - Initialization

    init(startDate: Date, endDate: Date) {
        self.startDate = startDate.normalizedDate()
        self.endDate = endDate.normalizedDate()
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        reloadSections()
        configureTableView()
        registerTableViewCells()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
}


// MARK: - View Configuration
//
private extension CustomDateRangeSelectionViewController {

    func configureNavigation() {
        title = NSLocalizedString("Custom Range", comment: "Custom Range selection title")

        // Don't show this controller's title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton

        configureLeftButton()
        configureRightButton()
    }

    func configureLeftButton() {
        let dismissButtonTitle = NSLocalizedString("Cancel",
                                                   comment: "Custom range screen - button title for closing the view")
        let leftBarButton = UIBarButtonItem(title: dismissButtonTitle,
                                            style: .plain,
                                            target: self,
                                            action: #selector(dismissButtonTapped))
        leftBarButton.tintColor = .white
        navigationItem.setLeftBarButton(leftBarButton, animated: false)
    }

    func configureRightButton() {
        let applyButtonTitle = NSLocalizedString("Apply",
                                                 comment: "Custom range screen - button title to apply selection")
        let rightBarButton = UIBarButtonItem(title: applyButtonTitle,
                                             style: .done,
                                             target: self,
                                             action: #selector(applyButtonTapped))
        rightBarButton.tintColor = .white
        navigationItem.setRightBarButton(rightBarButton, animated: false)
    }

    func configureMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    func configureTableView() {
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    func reloadSections() {
        let rangeTitle = NSLocalizedString(
            "Date Range",
            comment: "My Store > Custom Range > Date range section"
            ).uppercased()


        var rangeRows: [Row] = [.rangeStart, .rangeEnd]
        // Add picker row when necessary
        if let datePickerParentRow = datePickerParentRow, let parentIndex = rangeRows.firstIndex(of: datePickerParentRow) {
            rangeRows.insert(.datePicker, at: parentIndex + 1)
        }

        sections = [
            Section(title: rangeTitle, rows: rangeRows, footerHeight: CGFloat.leastNonzeroMagnitude),
        ]
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }

    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as RightDetailTableViewCell where row == .rangeStart:
            configureRangeStart(cell: cell)
        case let cell as RightDetailTableViewCell where row == .rangeEnd:
            configureRangeEnd(cell: cell)
        case let cell as DatePickerTableViewCell where row == .datePicker:
            configureDatePicker(cell: cell)
        default:
            fatalError()
        }
    }

    func configureRangeStart(cell: RightDetailTableViewCell) {
        cell.accessoryType = .none
        cell.textLabel?.text = NSLocalizedString("Start Date", comment: "My Store > Custom Range > Start date cell")
        cell.detailTextLabel?.text = startDate.toString(dateStyle: .long, timeStyle: .none)
    }

    func configureRangeEnd(cell: RightDetailTableViewCell) {
        cell.accessoryType = .none
        cell.textLabel?.text = NSLocalizedString("End Date", comment: "My Store > Custom Range > Start date cell")
        cell.detailTextLabel?.text = endDate.toString(dateStyle: .long, timeStyle: .none)
    }

    func configureDatePicker(cell: DatePickerTableViewCell) {
        let datePicker = cell.getPicker()
        datePicker.date = datePickerDate
        datePicker.maximumDate = Date()
        cell.onDateSelected = { [weak self] date in
            self?.dateChanged(date)
        }
    }
}


// MARK: - Convenience Methods
//
private extension CustomDateRangeSelectionViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    func indexPathForRow(row: Row) -> IndexPath? {
        for (index, section) in sections.enumerated() {
            if let rowIndex = section.rows.firstIndex(of: row) {
                return IndexPath(row: rowIndex, section: index)
            }
        }

        return nil
    }
}


// MARK: - Actions
//
private extension CustomDateRangeSelectionViewController {

    @objc func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func applyButtonTapped() {
        guard startDate.compare(endDate) != .orderedDescending else {
            warnInvalideRange()
            return
        }

        onSelectionCompleted?(startDate, endDate)
        dismiss(animated: true, completion: nil)
    }

    func warnInvalideRange() {
        let alert = UIAlertController(title: NSLocalizedString("Cannot Apply Range", comment: "Invalid custom range alert title."),
                                      message: NSLocalizedString("The start date must be before the end date.", comment: "Invalid custom range alert message."),
                                      preferredStyle: .alert)
        let cancel = UIAlertAction(title: NSLocalizedString("OK", comment: "Invalid custom range alert ack button."), style: .cancel, handler: nil)
        alert.addAction(cancel)

        present(alert, animated: true, completion: nil)
    }

    func rangeRowWasPressed(row: Row, indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let prevPickerIndexPath = indexPathForRow(row: .datePicker)
        datePickerParentRow = datePickerParentRow != row ? row : nil
        reloadSections()

        // Do fine grained row animations
        tableView.performBatchUpdates({
            if let prevPickerIndexPath = prevPickerIndexPath {
                tableView.deleteRows(at: [prevPickerIndexPath], with: .fade)
            }
            if let insertIndexPath = indexPathForRow(row: .datePicker) {
                tableView.insertRows(at: [insertIndexPath], with: .fade)
            }
        }, completion: nil)
    }

    func dateChanged(_ date: Date) {
        guard let datePickerParentRow = datePickerParentRow, let indexPathToReload = indexPathForRow(row: datePickerParentRow) else {
            return
        }

        switch datePickerParentRow {
        case .rangeStart:
            startDate = date
        case .rangeEnd:
            endDate = date
        case .datePicker:
            break
        }

        tableView.reloadRows(at: [indexPathToReload], with: .none)
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension CustomDateRangeSelectionViewController: UITableViewDataSource {

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
        return sections[section].footerHeight
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
extension CustomDateRangeSelectionViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = rowAtIndexPath(indexPath)
        switch row {
        case .rangeStart, .rangeEnd:
            rangeRowWasPressed(row: row, indexPath: indexPath)
        case .datePicker:
            break
        }
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
    let footerHeight: CGFloat
}

private enum Row: CaseIterable {
    case rangeStart
    case rangeEnd
    case datePicker

    var type: UITableViewCell.Type {
        switch self {
        case .rangeStart, .rangeEnd:
            return RightDetailTableViewCell.self
        case .datePicker:
            return DatePickerTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}
