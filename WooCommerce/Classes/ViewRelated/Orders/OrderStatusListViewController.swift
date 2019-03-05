import UIKit
import Yosemite

final class OrderStatusListViewController: UIViewController {
    /// Main TableView.
    ///
    @IBOutlet private var tableView: UITableView!

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) OrderStatuses in sync.
    ///
    private lazy var statusResultsController: ResultsController<StorageOrderStatus> = {
        let storageManager = AppDelegate.shared.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", StoresManager.shared.sessionManager.defaultStoreID ?? Int.min)
        let descriptor = NSSortDescriptor(key: "slug", ascending: true)

        return ResultsController<StorageOrderStatus>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: .valueChanged)
        return refreshControl
    }()

    /// Footer "Loading More" Spinner.
    ///
    private lazy var footerSpinnerView = FooterSpinnerView()

    override func viewDidLoad() {
        super.viewDidLoad()
        registerTableViewCells()
        configureNavigationBar()
        configureTableView()
        
        configureResultsController()
    }

    /// Setup: Results Controller
    ///
    private func configureResultsController() {
        statusResultsController.startForwardingEvents(to: tableView)
        try? statusResultsController.performFetch()
    }

    /// Registers all of the available TableViewCells
    ///
    private func registerTableViewCells() {
        let cells = [BasicTableViewCell.self]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.refreshControl = refreshControl
        tableView.tableFooterView = footerSpinnerView
    }

    @IBAction func pullToRefresh(sender: UIRefreshControl) {
//        WooAnalytics.shared.track(.ordersListPulledToRefresh)
//        syncingCoordinator.synchronizeFirstPage {
//            sender.endRefreshing()
//        }
    }
}

/// MARK: - Navigation bar
///
extension OrderStatusListViewController {
    func configureNavigationBar() {
        configureTitle()
        configureLeftButton()
        configureRightButton()
    }

    func configureTitle() {
        title = NSLocalizedString("Order Status", comment: "Change order status screen - Screen title")
    }

    func configureLeftButton() {
        let dismissButtonTitle = NSLocalizedString("Cancel",
                                                   comment: "Change order status screen - button title for closing the view")
        let leftBarButton = UIBarButtonItem(title: dismissButtonTitle,
                                            style: .plain,
                                            target: self,
                                            action: #selector(dismissButtonTapped))
        leftBarButton.tintColor = .white
        navigationItem.setLeftBarButton(leftBarButton, animated: false)
    }

    func configureRightButton() {
        let applyButtonTitle = NSLocalizedString("Apply",
                                               comment: "Change order status screen - button title to apply selection")
        let rightBarButton = UIBarButtonItem(title: applyButtonTitle,
                                             style: .done,
                                             target: self,
                                             action: #selector(applyButtonTapped))
        rightBarButton.tintColor = .white
        navigationItem.setRightBarButton(rightBarButton, animated: false)
    }

    @objc func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func applyButtonTapped() {
        print("==== apply button tapped ====")
    }
}


/// MARK: - UITableViewDatasource coformance
extension OrderStatusListViewController: UITableViewDataSource {
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return statusResultsController.sections.count
//    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return statusResultsController.sections[section].numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BasicTableViewCell.reuseIdentifier, for: indexPath) as? BasicTableViewCell else {
            fatalError()
        }

        //let viewModel = detailsViewModel(at: indexPath)
        let status = statusResultsController.object(at: indexPath)
        cell.textLabel?.text = status.name

        return cell
    }
}
