import UIKit
import Yosemite
import Gridicons
import SafariServices
import WordPressUI


/// ProductDetailsViewController: Displays the details for a given Product.
///
final class ProductDetailsViewController: UIViewController {

    /// EntityListener: Update / Deletion Notifications.
    ///
    private lazy var entityListener: EntityListener<Product> = {
        return EntityListener(storageManager: ServiceLocator.storageManager, readOnlyEntity: viewModel.product)
    }()

    /// Product view model
    ///
    private let viewModel: ProductDetailsViewModel

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


    // MARK: - Initializers

    /// Designated Initializer
    ///
    init(viewModel: ProductDetailsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    /// NSCoder Conformance
    ///
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // prepare UI
        configureNavigationTitle()
        configureEntityListener()
        configureMainView()
        configureTableView()
        registerTableViewCells()
        registerTableViewHeaderFooters()

        // prepare data
        initializeData()
        configureViewModel()
    }
}


// MARK: - Configuration
//
private extension ProductDetailsViewController {

    /// Setup: Navigation Title
    ///
    func configureNavigationTitle() {
        title = viewModel.title
    }

    /// Setup: EntityListener
    ///
    func configureEntityListener() {
        entityListener.onUpsert = { [weak self] product in
            guard let self = self else {
                return
            }

            self.viewModel.product = product
            self.reloadTableViewDataIfPossible()
        }
        entityListener.onDelete = { [weak self] in
            guard let self = self else {
                return
            }

            self.navigationController?.popViewController(animated: true)
        }
    }

    /// Setup: main view
    ///
    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        tableView.backgroundColor = .listBackground
        tableView.separatorColor = .systemColor(.separator)
        tableView.estimatedSectionHeaderHeight = viewModel.sectionHeight
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.refreshControl = refreshControl
        tableView.tableFooterView = UIView(frame: .zero)
    }

    /// Init the data
    ///
    func initializeData() {
        viewModel.reloadTableViewSectionsAndData()
    }

    /// Configure view model
    ///
    func configureViewModel() {
        configureViewModelForSuccess()
        configureViewModelForErrors()
    }

    /// Configure view model success
    ///
    func configureViewModelForSuccess() {
        viewModel.onReload = {  [weak self] in
            self?.reloadTableViewDataIfPossible()
        }
        viewModel.onPurchaseNoteTapped = { [weak self] in
            self?.presentPurchaseNoteIfPossible()
        }
    }

    /// Configure view model errors
    ///
    func configureViewModelForErrors() {
        viewModel.onError = { [weak self] in
            self?.navigationController?.dismiss(animated: true, completion: nil)
            self?.displayProductRemovedNotice()
        }
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        let cells = [
            ProductImagesHeaderTableViewCell.self,
            TitleBodyTableViewCell.self,
            TwoColumnTableViewCell.self,
            ProductReviewsTableViewCell.self,
            WooBasicTableViewCell.self,
            ReadMoreTableViewCell.self
        ]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }

    /// Registers all of the available TableViewHeaderFooters
    ///
    func registerTableViewHeaderFooters() {
        let headersAndFooters = [
            TwoColumnSectionHeaderView.self,
        ]

        for kind in headersAndFooters {
            tableView.register(kind.loadNib(), forHeaderFooterViewReuseIdentifier: kind.reuseIdentifier)
        }
    }
}


// MARK: - Action Handlers
//
private extension ProductDetailsViewController {

    @objc func pullToRefresh() {
        DDLogInfo("♻️ Requesting product detail data be reloaded...")
        viewModel.syncProduct() { [weak self] (error) in
            if let error = error {
                 DDLogError("⛔️ Error loading product details: \(error)")
                self?.displaySyncingErrorNotice()
            }
            self?.refreshControl.endRefreshing()
        }
    }
}


// MARK: - Notices
//
private extension ProductDetailsViewController {

    /// Displays a notice indicating that the current Product has been removed from the Store.
    ///
    func displayProductRemovedNotice() {
        let message = String.localizedStringWithFormat(
            NSLocalizedString("Product %ld has been removed from your store",
                comment: "Notice displayed when the onscreen product was just deleted. It reads: Product {product number} has been removed from your store."
        ), viewModel.productID)

        let notice = Notice(title: message, feedbackType: .error)
        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Displays a notice indicating that an error occurred while sync'ing.
    ///
    func displaySyncingErrorNotice() {
        let message = String.localizedStringWithFormat(
            NSLocalizedString("Unable to refresh Product #%ld",
                comment: "Notice displayed when an error occurs while refreshing a product. It reads: Unable to refresh product #{product number}"
        ), viewModel.productID)
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: message, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            self?.refreshControl.beginRefreshing()
            self?.pullToRefresh()
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension ProductDetailsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection(section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return viewModel.tableView(tableView, cellForRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.rowHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.heightForRow(at: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return viewModel.heightForHeader(in: section)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return viewModel.heightForFooter(in: section)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return viewModel.tableView(tableView, viewForHeaderInSection: section)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return viewModel.tableView(tableView, viewForFooterInSection: section)
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension ProductDetailsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.didSelectRow(at: indexPath, sender: self)
    }
}


// MARK: - Tableview helpers
//
private extension ProductDetailsViewController {

    /// Reloads the tableView's data, assuming the view has been loaded.
    ///
    func reloadTableViewDataIfPossible() {
        guard isViewLoaded else {
            return
        }

        tableView.reloadData()
    }

    /// Displays the full purchase note
    ///
    func presentPurchaseNoteIfPossible() {
        guard isViewLoaded else {
            return
        }

        let fancyAlert = FancyAlertViewController.makePurchaseNoteAlertController(with: viewModel.cleanedPurchaseNote)
        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController
        present(fancyAlert, animated: true)
    }
}
