import UIKit
import Yosemite


/// ProductDetailsViewController: Displays the details for a given Product.
///
final class ProductDetailsViewController: UIViewController {

    /// Product to be displayed
    ///
    private var product: Product {
        didSet {
            reloadTableViewSectionsAndData()
        }
    }

    /// Main TableView.
    ///
    @IBOutlet private weak var tableView: UITableView!

    /// Sections to be rendered
    ///
    private var sections = [Section]()

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return refreshControl
    }()

    /// EntityListener: Update / Deletion Notifications.
    ///
    private lazy var entityListener: EntityListener<Product> = {
        return EntityListener(storageManager: AppDelegate.shared.storageManager, readOnlyEntity: product)
    }()

    // MARK: - Initializers

    /// Designated Initializer
    ///
    init(product: Product) {
        self.product = product
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
        configureNavigationTitle()
        configureTableView()
        registerTableViewCells()
        registerTableViewHeaderFooters()
        reloadTableViewSectionsAndData()
    }
}


// MARK: - Configuration
//
private extension ProductDetailsViewController {

    /// Setup: TableView
    ///
    func configureTableView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.estimatedSectionFooterHeight = Constants.rowHeight
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.refreshControl = refreshControl
        tableView.separatorInset = .zero
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        let cells = [
            BasicTableViewCell.self
        ]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }

    /// Setup: Navigation Title
    ///
    func configureNavigationTitle() {
        title = product.name
    }

    /// Setup: EntityListener
    ///
    func configureEntityListener() {
        entityListener.onUpsert = { [weak self] product in
            guard let self = self else {
                return
            }

            self.product = product
        }

        entityListener.onDelete = { [weak self] in
            guard let self = self else {
                return
            }

            self.navigationController?.dismiss(animated: true, completion: nil)
            self.displayProductRemovedNotice()
        }
    }

    /// Registers all of the available TableViewHeaderFooters
    ///
    func registerTableViewHeaderFooters() {
        let headersAndFooters = [
            TwoColumnSectionHeaderView.self,
            ShowHideSectionFooter.self
        ]

        for kind in headersAndFooters {
            tableView.register(kind.loadNib(), forHeaderFooterViewReuseIdentifier: kind.reuseIdentifier)
        }
    }
}


// MARK: - Action Handlers
//
extension ProductDetailsViewController {

    @objc func pullToRefresh() {
        DDLogInfo("♻️ Requesting product detail data be reloaded...")
        syncProduct() { [weak self] (error) in
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
        ), product.productID)

        let notice = Notice(title: message, feedbackType: .error)
        AppDelegate.shared.noticePresenter.enqueue(notice: notice)
    }

    /// Displays a notice indicating that an error occurred while sync'ing.
    ///
    func displaySyncingErrorNotice() {
        let message = String.localizedStringWithFormat(
            NSLocalizedString("Unable to refresh Product #%ld",
                comment: "Notice displayed when an error occurs while refreshing a product. It reads: Unable to refresh product #{product number}"
        ), product.productID)
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: message, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            self?.refreshControl.beginRefreshing()
            self?.pullToRefresh()
        }

        AppDelegate.shared.noticePresenter.enqueue(notice: notice)
    }
}


// MARK: - Sync'ing Helpers
//
private extension ProductDetailsViewController {

    func syncProduct(onCompletion: ((Error?) -> ())? = nil) {
        let action = ProductAction.retrieveProduct(siteID: product.siteID, productID: product.productID) { [weak self] (product, error) in
            guard let self = self, let product = product else {
                DDLogError("⛔️ Error synchronizing Product: \(error.debugDescription)")
                onCompletion?(error)
                return
            }

            self.product = product
            onCompletion?(nil)
        }

        StoresManager.shared.dispatch(action)
    }
}


// MARK: - Cell Configuration
//
private extension ProductDetailsViewController {

    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as BasicTableViewCell:
            configureProductDetails(cell: cell)
        default:
            fatalError("Unidentified row type")
        }
    }

    func configureProductDetails(cell: BasicTableViewCell) {
        cell.textLabel?.text = product.name
        cell.detailTextLabel?.text = product.fullDescription
        cell.accessoryType = .none
        cell.selectionStyle = .none
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension ProductDetailsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if sections[section].title == nil {
            // iOS 11 table bug. Must return a tiny value to collapse `nil` or `empty` section headers.
            return .leastNonzeroMagnitude
        }

        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let leftText = sections[section].title else {
            return nil
        }

        let headerID = TwoColumnSectionHeaderView.reuseIdentifier
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerID) as? TwoColumnSectionHeaderView else {
            fatalError()
        }

        headerView.leftText = leftText
        headerView.rightText = sections[section].rightTitle

        return headerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let lastSectionIndex = sections.count - 1

        if sections[section].footer != nil || section == lastSectionIndex {
            return UITableView.automaticDimension
        }

        return .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension ProductDetailsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rowAtIndexPath(indexPath) {
        default:
            break
        }
    }
}


// MARK: - Private helpers
//
private extension ProductDetailsViewController {

    /// Returns the Row enum value for the provided IndexPath
    ///
    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
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
}


// MARK: - Sections
//
private extension ProductDetailsViewController {

    /// Setup: Sections
    ///
    func reloadSections() {
        let summary = Section(row: .productSummary)
        // TODO: More sections go here
        sections = [summary].compactMap { $0 }
    }
}


// MARK: - Constants
//
private extension ProductDetailsViewController {

    enum Constants {
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
    }

    struct Section {
        let title: String?
        let rightTitle: String?
        let footer: String?
        let rows: [Row]

        init(title: String? = nil, rightTitle: String? = nil, footer: String? = nil, rows: [Row]) {
            self.title = title
            self.rightTitle = rightTitle
            self.footer = footer
            self.rows = rows
        }

        init(title: String? = nil, rightTitle: String? = nil, footer: String? = nil, row: Row) {
            self.init(title: title, rightTitle: rightTitle, footer: footer, rows: [row])
        }
    }

    enum Row {
        case productSummary
        // TODO: More rows go here

        var reuseIdentifier: String {
            switch self {
            case .productSummary:
                return BasicTableViewCell.reuseIdentifier
            }
        }
    }
}
