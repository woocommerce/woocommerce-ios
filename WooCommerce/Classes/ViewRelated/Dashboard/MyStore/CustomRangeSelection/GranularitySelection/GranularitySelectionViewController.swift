import UIKit
import Yosemite


// MARK: - GranularitySelectionViewController
//
class GranularitySelectionViewController: UIViewController {

    /// Closure to be executed whenever the selected granularity is changed
    ///
    var onSelectionChanged: ((_ granularity: StatGranularity) -> Void)?

    /// Main TableView
    ///
    @IBOutlet weak var tableView: UITableView!

    /// Selected granularity
    ///
    private var granularity: StatGranularity

    init(granularity: StatGranularity) {
        self.granularity = granularity
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
        configureTableView()
        registerTableViewCells()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let rowIndex = Constants.granularities.firstIndex(of: granularity) else {
            return
        }
        self.tableView.selectRow(at: IndexPath(row: rowIndex, section: 0), animated: true, scrollPosition: .none)
    }
}


// MARK: - View Configuration
//
private extension GranularitySelectionViewController {

    func configureNavigation() {
        title = NSLocalizedString("Display as", comment: "Granularity selection title")

        // Don't show this controller's title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton
    }

    func configureMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    func configureTableView() {
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    func registerTableViewCells() {
        let cells = [StatusListTableViewCell.self]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension GranularitySelectionViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Constants.granularities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: StatusListTableViewCell.reuseIdentifier,
                                                       for: indexPath) as? StatusListTableViewCell else {
                                                        fatalError()
        }

        let granularity = Constants.granularities[indexPath.row]
        cell.textLabel?.text = granularity.pluralizedString

        return cell
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension GranularitySelectionViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // iOS 11 table bug. Must return a tiny value to collapse `nil` or `empty` section headers.
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let granularity = Constants.granularities[indexPath.row]

        self.granularity = granularity
        onSelectionChanged?(granularity)
    }
}


// MARK: - Private Types
//
private struct Constants {
    static let rowHeight = CGFloat(44)
    static let granularities: [StatGranularity] = [.day, .week, .month, .year]
}
