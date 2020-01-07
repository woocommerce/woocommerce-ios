import UIKit
import Yosemite


// MARK: - RefundedProductsViewController: Displays a list of all the refunded products.
//
final class RefundedProductsViewController: UIViewController {
    /// Main TableView.
    ///
    @IBOutlet private weak var tableView: UITableView!

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return refreshControl
    }()

    /// Refunded Products to be rendered!
    ///
    var viewModel: RefundedProductsViewModel! {
        didSet {
            reloadTableViewSectionsAndData()
        }
    }

    /// Designated initalizer.
    ///
    init(viewModel: RefundedProductsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    /// NSCoder conformance.
    ///
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// EntityListener: Update / Deletion Notifications.
    ///
    private lazy var entityListener: EntityListener<Order> = {
        return EntityListener(storageManager: ServiceLocator.storageManager, readOnlyEntity: viewModel.order)
    }()

    /// Send notices to the user.
    ///
    private let notices = OrderDetailsNotices()

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureTableView()
        registerTableViewCells()
        registerTableViewHeaderFooters()
        configureEntityListener()
        configureViewModel()
        reloadSections()
    }
}


// MARK: - Setup
//
private extension RefundedProductsViewController {
    /// Setup: Navigation.
    ///
    func configureNavigation() {
        title = NSLocalizedString("Refunded Products",
                                  comment: "Order > Order Details > 'N Items' cell tapped > Refunded Products title")
    }

    /// Setup: TableView.
    ///
    func configureTableView() {
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.refreshControl = refreshControl

        tableView.dataSource = viewModel.dataSource
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

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        viewModel.registerTableViewCells(tableView)
    }

    /// Registers all of the available TableViewHeaderFooters
    ///
    func registerTableViewHeaderFooters() {
        viewModel.registerTableViewHeaderFooters(tableView)
    }

    /// Setup: EntityListener
    ///
    func configureEntityListener() {
        entityListener.onUpsert = { [weak self] order in
            guard let self = self else {
                return
            }
            self.viewModel.updateOrderStatus(order: order)
            self.reloadTableViewSectionsAndData()
        }

        entityListener.onDelete = { [weak self] in
            guard let self = self else {
                return
            }

            self.navigationController?.popViewController(animated: true)
            self.displayOrderDeletedNotice(order: self.viewModel.order)
        }
    }

    /// Setup: Configure viewModel
    ///
    func configureViewModel() {
        viewModel.configureResultsControllers { [weak self] in
            self?.reloadTableViewSectionsAndData()
        }
    }
}


// MARK: - Sections
//
private extension RefundedProductsViewController {

    func reloadSections() {
        viewModel.reloadSections()
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension RefundedProductsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.tableView(tableView, in: self, didSelectRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return viewModel.dataSource.viewForHeaderInSection(section, tableView: tableView)
    }
}


// MARK: - Notices
//
private extension RefundedProductsViewController {
    /// Displays a Notice onscreen, indicating that the current Order has been deleted from the Store.
    ///
    func displayOrderDeletedNotice(order: Order) {
        notices.displayOrderDeletedNotice(order: order)
    }
}


// MARK: - Action Handlers
//
extension RefundedProductsViewController {

    @objc func pullToRefresh() {
        ServiceLocator.analytics.track(.refundedProductsPulledToRefresh)
        let group = DispatchGroup()

        group.enter()
        syncOrder { _ in
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }
}


// MARK: - Sync'ing Helpers
//
private extension RefundedProductsViewController {
    func syncOrder(onCompletion: ((Error?) -> ())? = nil) {
        viewModel.syncOrder { [weak self] (order, error) in
            guard let self = self, let order = order else {
                onCompletion?(error)
                return
            }

            self.viewModel.update(order: order)

            onCompletion?(nil)
        }
    }
}


// MARK: - Constants
//
extension RefundedProductsViewController {
    enum Constants {
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
    }
}
