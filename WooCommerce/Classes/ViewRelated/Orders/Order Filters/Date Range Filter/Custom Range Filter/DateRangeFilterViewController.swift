import UIKit

// MARK: - DateRangeFilterViewController
// Allow to filter the orders by a range of dates
//
final class DateRangeFilterViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    // Completion callback
    //
    typealias Completion = (Date?, Date?) -> Void
    private let onCompletion: Completion

    private var startDate: Date?
    private var endDate: Date?

    // Indicate when the start or the end date picker is expanded
    //
    private var startDateExpanded: Bool = false
    private var endDateExpanded: Bool = false

    private var rows: [Row] = []

    /// Init
    ///
    init(startDate: Date?,
         endDate: Date?,
         completion: @escaping Completion) {
        self.startDate = startDate
        self.endDate = endDate
        onCompletion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureMainView()
        updateRows()
        configureTableView()
    }
}

// MARK: - View Configuration
//
private extension DateRangeFilterViewController {

    func configureNavigationBar() {
        title = Localization.navigationBarTitle
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self

        /// Registers all of the available TableViewCells
        ///
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }

        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()
    }

    func updateRows() {
        var tempRows: [Row] = [.startDateTitle]
        if startDateExpanded {
            tempRows.append(.startDatePicker)
        }
        tempRows.append(.endDateTitle)
        if endDateExpanded {
            tempRows.append(.endDatePicker)
        }
        rows = tempRows
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension DateRangeFilterViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)
        return cell
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension DateRangeFilterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rows[indexPath.row] {
        case .startDateTitle:
            startDateExpanded.toggle()
            updateRows()
            tableView.reloadData()
        case .endDateTitle:
            endDateExpanded.toggle()
            updateRows()
            tableView.reloadData()
        default:
            return
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - Cell configuration
//
private extension DateRangeFilterViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TitleAndValueTableViewCell where row == .startDateTitle:
            configureStartDateTitle(cell: cell)
            break
        case let cell as DatePickerTableViewCell where row == .startDatePicker:
            configureStartDatePicker(cell: cell)
            break
        case let cell as TitleAndValueTableViewCell where row == .endDateTitle:
            configureEndDateTitle(cell: cell)
            break
        case let cell as DatePickerTableViewCell where row == .endDatePicker:
            configureEndDatePicker(cell: cell)
            break
        default:
            fatalError()
        }
    }

    func configureStartDateTitle(cell: TitleAndValueTableViewCell) {
        cell.updateUI(title: Localization.startDateTitle, value: startDate?.toString(dateStyle: .medium, timeStyle: .none))
        cell.selectionStyle = .none
    }

    func configureStartDatePicker(cell: DatePickerTableViewCell) {
        if let startDate = startDate {
            cell.getPicker().setDate(startDate, animated: false)
        }
        cell.getPicker().maximumDate = endDate
        cell.getPicker().preferredDatePickerStyle = .inline
        cell.onDateSelected = { [weak self] date in
            guard let self = self else {
                return
            }
            self.startDate = date
            self.tableView.reloadData()
            self.onCompletion(self.startDate, self.endDate)
        }
        cell.selectionStyle = .none
    }

    func configureEndDateTitle(cell: TitleAndValueTableViewCell) {
        cell.updateUI(title: Localization.endDateTitle, value: endDate?.toString(dateStyle: .medium, timeStyle: .none))
        cell.selectionStyle = .none
    }

    func configureEndDatePicker(cell: DatePickerTableViewCell) {
        if let endDate = endDate {
            cell.getPicker().setDate(endDate, animated: false)
        }
        cell.getPicker().minimumDate = startDate
        cell.getPicker().preferredDatePickerStyle = .inline
        cell.onDateSelected = { [weak self] date in
            guard let self = self else {
                return
            }
            self.endDate = date
            self.tableView.reloadData()
            self.onCompletion(self.startDate, self.endDate)
        }
        cell.selectionStyle = .none
    }
}

// MARK: - Private Types
//
private extension DateRangeFilterViewController {

    enum Row: CaseIterable {
        case startDateTitle
        case startDatePicker
        case endDateTitle
        case endDatePicker

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .startDateTitle, .endDateTitle:
                return TitleAndValueTableViewCell.self
            case .startDatePicker, .endDatePicker:
                return DatePickerTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

private extension DateRangeFilterViewController {
    enum Localization {
        static let navigationBarTitle = NSLocalizedString("Custom Range",
                                                          comment: "Navigation title of the orders filter selector screen for custom date range")
        static let startDateTitle = NSLocalizedString("Start Date", comment: "Label for one of the filters in order custom date range")
        static let endDateTitle = NSLocalizedString("End Date", comment: "Label for one of the filters in order custom date range")
    }
}
