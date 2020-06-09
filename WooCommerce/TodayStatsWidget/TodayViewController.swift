import UIKit
import NotificationCenter

final class TodayViewController: UIViewController {
        
    @IBOutlet private weak var tableView: UITableView!
    
    /// Table Sections to be rendered
    ///
    private var sections: [Section] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        sections = [Section(rows: [.todayStats, .selectedWebsite])]
        
    }
        
    
 
}

// MARK: - Widget Updating
extension TodayViewController: NCWidgetProviding {
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
}

// MARK: - View Configuration
//
private extension TodayViewController {

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .clear
        tableView.removeLastCellSeparator()
        
        registerTableViewCells()

        tableView.dataSource = self
        tableView.delegate = self
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension TodayViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
    
}

// MARK: - UITableViewDelegate Conformance
//
extension TodayViewController: UITableViewDelegate {
}

// MARK: - Cell configuration
//
private extension TodayViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TodayStatsTableViewCell where row == .todayStats:
            configureTodayStats(cell: cell)
        case let cell as SelectedWebsiteInTodayWidgetTableViewCell where row == .selectedWebsite:
            configureSelectedWebsite(cell: cell)
        default:
            fatalError()
            break
        }
    }
    
    func configureTodayStats(cell: TodayStatsTableViewCell) {
    }
    
    func configureSelectedWebsite(cell: SelectedWebsiteInTodayWidgetTableViewCell) {
        cell.textLabel?.text = "woocommerce.com"
    }
}
// MARK: - Private Types
//
private extension TodayViewController {

    struct Section {
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case todayStats
        case selectedWebsite

        var type: UITableViewCell.Type {
            switch self {
            case .todayStats:
                return TodayStatsTableViewCell.self
            case .selectedWebsite:
                return SelectedWebsiteInTodayWidgetTableViewCell.self
            }
        }

        var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}
