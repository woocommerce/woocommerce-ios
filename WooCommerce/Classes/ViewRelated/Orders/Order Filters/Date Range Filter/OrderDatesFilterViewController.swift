import UIKit

// MARK: - OrderDatesFilterViewController
// Display a list of options for filtering orders by different type of dates.
//
final class OrderDatesFilterViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    // Completion callback
    //
    typealias Completion = (OrderDateRangeFilter?) -> Void
    private let onCompletion: Completion

    private var rows: [OrderDateRangeFilter] = []

    private var selected: OrderDateRangeFilter?

    /// Init
    ///
    init(selected: OrderDateRangeFilter?,
         completion: @escaping Completion) {
        self.selected = selected
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
        configureRows()
        configureTableView()
    }
}

// MARK: - View Configuration
//
private extension OrderDatesFilterViewController {

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
        for row in OrderDateRangeFilterEnum.allCases {
            tableView.registerNib(for: row.cellType)
        }

        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()
    }

    func configureRows() {
        rows = [.init(filter: .any),
                    .init(filter: .today),
                    .init(filter: .last2Days),
                    .init(filter: .last7Days),
                    .init(filter: .last30Days),
                    .init(filter: .custom, startDate: selected?.startDate, endDate: selected?.endDate)]
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension OrderDatesFilterViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.filter.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)
        return cell
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension OrderDatesFilterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rows[indexPath.row].filter {
        case .custom:
            // Open the View Controller for selecting a custom range of dates
            //
            let dateRangeFilterVC = DateRangeFilterViewController(startDate: selected?.startDate,
                                                                  endDate: selected?.endDate) { [weak self] (startDate, endDate) in
                guard let self = self else { return }
                self.selected = OrderDateRangeFilter(filter: .custom, startDate: startDate, endDate: endDate)
                self.configureRows()
                self.onCompletion(self.selected)
                self.tableView.reloadData()
            }
            navigationController?.pushViewController(dateRangeFilterVC, animated: true)
        case .any:
            selected = nil
            onCompletion(nil)
            configureRows()
            tableView.reloadData()
        default:
            selected = rows[indexPath.row]
            onCompletion(selected)
            configureRows()
            tableView.reloadData()
            return
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - Cell configuration
//
private extension OrderDatesFilterViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: OrderDateRangeFilter, at indexPath: IndexPath) {
        switch cell {
        case let cell as BasicTableViewCell:
            configureStandardFilter(cell: cell, row: row)
        case let cell as TitleAndValueTableViewCell where row.filter == .custom:
            configureCustomDateRangeFilter(cell: cell, row: row)
        default:
            fatalError()
            break
        }
    }

    func configureStandardFilter(cell: BasicTableViewCell, row: OrderDateRangeFilter) {
        cell.textLabel?.text = row.description
        cell.selectionStyle = .none
        if row.filter == selected?.filter || row.filter == .any && selected == nil {
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }
    }

    func configureCustomDateRangeFilter(cell: TitleAndValueTableViewCell, row: OrderDateRangeFilter) {
        var formattedDates: String = ""
        if let startDateFormatted = row.startDate?.toString(dateStyle: .medium, timeStyle: .none) {
            formattedDates = startDateFormatted
        }
        if row.startDate != nil && row.endDate != nil {
            formattedDates = formattedDates + " - "
        }
        if let endDateFormatted = row.endDate?.toString(dateStyle: .medium, timeStyle: .none) {
            formattedDates = formattedDates + endDateFormatted
        }

        cell.updateUI(title: row.description, value: formattedDates)
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator
    }
}

private extension OrderDatesFilterViewController {
    enum Localization {
        static let navigationBarTitle = NSLocalizedString("Date Range",
                                                          comment: "Navigation title of the orders filter selector screen for date range")
    }
}
