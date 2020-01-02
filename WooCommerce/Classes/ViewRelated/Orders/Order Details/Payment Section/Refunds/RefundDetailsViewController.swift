import UIKit
import Yosemite


// MARK: - RefundDetailsViewController: Displays the details for a given Refund.
//
final class RefundDetailsViewController: UIViewController {
    /// Main TableView.
    ///
    @IBOutlet weak var tableView: UITableView!

    /// Refund to be rendered.
    ///
    var viewModel: RefundDetailsViewModel! {
        didSet {
            reloadTableViewSectionsAndData()
        }
    }

    /// Designated initalizer.
    ///
    init(viewModel: RefundDetailsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    /// NSCoder conformance.
    ///
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - View Lifecycle
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureTableView()
        registerTableViewCells()
        registerTableViewHeaderFooters()
        configureViewModel()
        reloadSections()
    }

    /// Setup: Navigation.
    ///
    func configureNavigation() {
        let refundTitle = NSLocalizedString("Refund #%@", comment: "It reads: Refund #<refund ID>")
        title = String.localizedStringWithFormat(refundTitle, String(viewModel.refund.refundID))
    }

    /// Setup: TableView.
    ///
    func configureTableView() {
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension

        tableView.dataSource = viewModel.dataSource
    }

    private func configureViewModel() {
        viewModel.configureResultsControllers { [weak self] in
            self?.reloadTableViewSectionsAndData()
        }
    }

    /// Reloads the tableView's data, assuming the view has been loaded.
    ///
    func reloadTableViewDataIfPossible() {
        guard isViewLoaded else {
            return
        }

        tableView.reloadData()
    }

    /// Reloads the tableView's sections and data.
    ///
    func reloadTableViewSectionsAndData() {
        reloadSections()
        reloadTableViewDataIfPossible()
    }

    /// Registers all of the available UITableViewCells.
    ///
    func registerTableViewCells() {
        viewModel.registerTableViewCells(tableView)
    }

    /// Registers all of the available TableViewHeaderFooters.
    ///
    func registerTableViewHeaderFooters() {
        viewModel.registerTableViewHeaderFooters(tableView)
    }
}


// MARK: - Sections
//
private extension RefundDetailsViewController {
    /// Reload the tableview section data.
    ///
    func reloadSections() {
        viewModel.reloadSections()
    }
}


// MARK: - Register table view cells
//
extension RefundDetailsViewModel {
    /// Registers all of the available UITableViewCells.
    ///
    func registerTableViewCells(_ tableView: UITableView) {
        let cells = [
            ProductDetailsTableViewCell.self,
        ]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }

    /// Registers all of the available TableViewHeaderFooters.
    ///
    func registerTableViewHeaderFooters(_ tableView: UITableView) {
        let headersAndFooters = [
            TwoColumnSectionHeaderView.self
        ]

        for kind in headersAndFooters {
            tableView.register(kind.loadNib(), forHeaderFooterViewReuseIdentifier: kind.reuseIdentifier)
        }
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension RefundDetailsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.tableView(tableView, in: self, didSelectRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return viewModel.dataSource.viewForHeaderInSection(section, tableView: tableView)
    }
}


// MARK: - Constants
//
extension RefundDetailsViewController {
    enum Constants {
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
    }
}
