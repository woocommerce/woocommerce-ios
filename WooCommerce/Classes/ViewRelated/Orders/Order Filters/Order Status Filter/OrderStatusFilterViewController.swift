import UIKit
import Yosemite

// MARK: - OrderStatusFilterViewController
// Display a list of options for filtering orders by different type of status.
// Multiples selection allowed.
//
final class OrderStatusFilterViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    // Completion callback
    //
    typealias Completion = ([OrderStatusEnum]) -> Void
    private let onCompletion: Completion

    private var rows: [Row] = []

    private var selected: [OrderStatusEnum]

    private var allowedStatuses: [OrderStatus] = []

    /// Init
    ///
    init(selected: [OrderStatusEnum],
         allowedStatuses: [OrderStatus],
         completion: @escaping Completion) {
        self.selected = selected
        self.allowedStatuses = allowedStatuses
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
private extension OrderStatusFilterViewController {

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
        tableView.registerNib(for: BasicTableViewCell.self)

        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()
    }

    func configureRows() {
        rows = [.any]
        for status in allowedStatuses {
            switch status.status {
            case .pending:
                rows.append(.pending)
            case .processing:
                rows.append(.processing)
            case .onHold:
                rows.append(.onHold)
            case .failed:
                rows.append(.failed)
            case .cancelled:
                rows.append(.cancelled)
            case .completed:
                rows.append(.completed)
            case .refunded:
                rows.append(.refunded)
            case .custom:
                rows.append(Row.custom(status))
            default:
                break
            }
        }
    }

    func selectOrDelesectRow(_ row: Row) {
        guard let status = row.status else {
            return
        }
        if selected.contains(status) {
            selected.removeAll { $0 == status }
        }
        else {
            selected.append(status)
        }
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension OrderStatusFilterViewController: UITableViewDataSource {

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
extension OrderStatusFilterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rows[indexPath.row] {
        case .any:
            selected = []
            onCompletion(selected)
        default:
            selectOrDelesectRow(rows[indexPath.row])
            onCompletion(selected)
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - Cell configuration
//
private extension OrderStatusFilterViewController {
    enum Row {

        // The order of the statuses declaration is according to the Order's lifecycle
        // and it is used to determine the user facing display order using the synthesized allCases
        case any
        case pending
        case processing
        case onHold
        case completed
        case cancelled
        case refunded
        case failed
        case custom(OrderStatus)

        var status: OrderStatusEnum? {
            switch self {
            case .any:
                return nil
            case .pending:
                return .pending
            case .processing:
                return .processing
            case .onHold:
                return .onHold
            case .failed:
                return .failed
            case .cancelled:
                return .cancelled
            case .completed:
                return .completed
            case .refunded:
                return .refunded
            case .custom(let value):
                return value.status
            }
        }

        var description: String? {
            switch self {
            case .custom(let status):
                return status.name ?? status.slug
            default:
                return self.status?.description
            }
        }

        var type: UITableViewCell.Type {
            BasicTableViewCell.self
        }

        var reuseIdentifier: String {
            type.reuseIdentifier
        }
    }

    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as BasicTableViewCell:
            configureStatus(cell: cell, row: row)
        default:
            assertionFailure("The type of cell (\(type(of: cell)) does not match the type (\(row.type)) for row: \(row)")
        }
    }

    func configureStatus(cell: BasicTableViewCell, row: Row) {
        switch row {
        case .any:
            cell.textLabel?.text = Localization.anyStatusCase
            cell.accessoryType = selected.isEmpty ? .checkmark : .none
        default:
            cell.textLabel?.text = row.description
            if selected.contains(where: { $0 == row.status }) {
                cell.accessoryType = .checkmark
            }
            else {
                cell.accessoryType = .none
            }
        }

        cell.selectionStyle = .none
    }
}

private extension OrderStatusFilterViewController {
    enum Localization {
        static let anyStatusCase = NSLocalizedString("Any",
                                                     comment: "Case Any in Order Filters for Order Statuses")
        static let navigationBarTitle = NSLocalizedString("Order Status",
                                                          comment: "Navigation title of the orders filter selector screen for order statuses")
    }
}
