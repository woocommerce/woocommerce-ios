import UIKit

class PerformanceViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private var viewModel = PerformanceViewModel()

    private var rows = [Row]()

    override func viewDidLoad() {
        super.viewDidLoad()

        rows = [
            .performanceGraph,
            .resetStatisticsButton
        ]

        configureNavigation()
        setTableFooter()
        setTableSource()
    }

    private func setTableSource() {
        tableView.registerNib(for: HistogramTableViewCell.self)
        tableView.registerNib(for: ButtonTableViewCell.self)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }

    private func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as HistogramTableViewCell where row == .performanceGraph:
            configureGraph(cell: cell)
        case let cell as ButtonTableViewCell where row == .resetStatisticsButton:
            configureButton(cell: cell)
        default:
            fatalError()
        }
    }

    private func configureGraph(cell: HistogramTableViewCell) {
        cell.selectionStyle = .none
        let histogram = HistogramView()
        histogram.setData(data: viewModel.responseTimes)
        cell.backgroundView = histogram
    }

    private func configureButton(cell: ButtonTableViewCell) {
        let buttonTitle = NSLocalizedString(
            "Reset Statistics",
            comment: ""
        )
        cell.configure(title: buttonTitle) { [weak self] in
            self?.onPressedReset()
        }
        cell.selectionStyle = .none
    }

    private func setTableFooter() {
        tableView.tableFooterView = UIView()
    }

    private func onPressedReset() {
        viewModel.resetStatistics()
    }
}

private enum Row: CaseIterable {
    case performanceGraph
    case resetStatisticsButton

    var type: UITableViewCell.Type {
        switch self {
        case .performanceGraph:
            return HistogramTableViewCell.self
        case .resetStatisticsButton:
            return ButtonTableViewCell.self
        }
    }

    var height: CGFloat {
        switch self {
        case .performanceGraph:
            return 250
        case .resetStatisticsButton:
            return UITableView.automaticDimension
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}

// MARK: - View Configuration
//
private extension PerformanceViewController {
    func configureNavigation() {
        title = NSLocalizedString("Performance", comment: "")

        // Don't show the Settings title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton
    }
}

// MARK: - Convenience Methods
//
private extension PerformanceViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return rows[indexPath.row]
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension PerformanceViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
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
extension PerformanceViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rowAtIndexPath(indexPath)
        return row.height
    }
}
