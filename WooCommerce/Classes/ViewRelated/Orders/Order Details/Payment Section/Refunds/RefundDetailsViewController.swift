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
    var viewModel: RefundDetailsViewModel {
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

        setUpNavigation()
        configureTableView()
        registerTableViewCells()
        registerTableViewHeaderFooters()
        configureViewModel()
    }

    /// Setup: Navigation.
    ///
    func setUpNavigation() {
        let refundTitle = NSLocalizedString("Refund #%ld", comment: "It reads: Refund #<refund ID>")
        title = String.localizedStringWithFormat(refundTitle, viewModel.refund.refundID)
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
            PickListTableViewCell.self,
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


// MARK: - Constants
//
extension RefundDetailsViewController {
    enum Constants {
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
    }
}
