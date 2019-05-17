import UIKit
import Yosemite
import Gridicons


/// ProductDetailsViewController: Displays the details for a given Product.
///
final class ProductDetailsViewController: UIViewController {

    /// Product view model
    ///
    public var viewModel: ProductDetailsViewModel

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

    /// Grab the first available image for a product.
    ///
    private var imageURL: URL? {
        guard let productImageURLString = product.images.first?.src else {
            return nil
        }
        return URL(string: productImageURLString)
    }

    /// Check to see if the product has an image URL.
    ///
    private var productHasImage: Bool {
        return imageURL != nil
    }

    /// Currency Formatter
    ///
    private var currencyFormatter = CurrencyFormatter()


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
        configureMainView()
        configureTableView()
        registerTableViewCells()
        registerTableViewHeaderFooters()
        reloadTableViewSectionsAndData()
    }
}


// MARK: - Configuration
//
private extension ProductDetailsViewController {

    /// Setup: Navigation Title
    ///
    func configureNavigationTitle() {
        title = product.name
    }

    /// Setup: main view
    ///
    func configureMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    /// Setup: TableView
    ///
    func configureTableView() {
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.estimatedSectionHeaderHeight = Metrics.sectionHeight
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Metrics.estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.refreshControl = refreshControl
        tableView.separatorInset = .zero
        tableView.tableFooterView = UIView(frame: .zero)
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

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        let cells = [
            LargeImageTableViewCell.self,
            TitleBodyTableViewCell.self,
            TwoColumnTableViewCell.self,
            ProductReviewsTableViewCell.self,
            WooBasicTableViewCell.self
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
        case let cell as LargeImageTableViewCell:
            configureProductImage(cell)
        case let cell as TitleBodyTableViewCell where row == .productName:
            configureProductName(cell)
        case let cell as TwoColumnTableViewCell where row == .totalOrders:
            configureTotalOrders(cell)
        case let cell as ProductReviewsTableViewCell:
            configureReviews(cell)
        case let cell as WooBasicTableViewCell where row == .permalink:
            configurePermalink(cell)
        case let cell as WooBasicTableViewCell where row == .affiliateLink:
            configureAffiliateLink(cell)
        case let cell as TitleBodyTableViewCell where row == .price:
            configurePrice(cell)
        case let cell as TitleBodyTableViewCell where row == .inventory:
            configureInventory(cell)
        case let cell as TitleBodyTableViewCell where row == .sku:
            configureSku(cell)
        case let cell as TitleBodyTableViewCell where row == .affiliateInventory:
            configureAffiliateInventory(cell)
        default:
            fatalError("Unidentified row type")
        }
    }

    func configureProductImage(_ cell: LargeImageTableViewCell) {
        guard let mainImageView = cell.mainImageView else {
            return
        }

        if productHasImage {
            cell.heightConstraint.constant = Metrics.productImageHeight
            mainImageView.downloadImage(from: imageURL, placeholderImage: UIImage.productPlaceholderImage)
        } else {
            cell.heightConstraint.constant = Metrics.emptyProductImageHeight
            let size = CGSize(width: tableView.frame.width, height: Metrics.emptyProductImageHeight)
            mainImageView.image = StyleManager.wooWhite.image(size)
        }

        if product.productStatus != .publish {
            cell.textBadge?.applyPaddedLabelSubheadStyles()
            cell.textBadge?.layer.backgroundColor = StyleManager.defaultTextColor.cgColor
            cell.textBadge?.textColor = StyleManager.wooWhite
            cell.textBadge?.text = product.productStatus.description
        }
    }

    func configureProductName(_ cell: TitleBodyTableViewCell) {
        cell.accessoryType = .none
        cell.selectionStyle = .none
        cell.titleLabel?.text = NSLocalizedString("Title", comment: "Product details screen — product title descriptive label")
        cell.bodyLabel?.applySecondaryBodyStyle()
        cell.bodyLabel?.text = product.name
        cell.secondBodyLabel.isHidden = true
    }

    func configureTotalOrders(_ cell: TwoColumnTableViewCell) {
        cell.selectionStyle = .none
        cell.leftLabel?.text = NSLocalizedString("Total Orders", comment: "Product details screen - total orders descriptive label")
        cell.rightLabel?.applySecondaryBodyStyle()
        cell.rightLabel.textInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        cell.rightLabel?.text = String(product.totalSales)
    }

    func configureReviews(_ cell: ProductReviewsTableViewCell) {
        cell.selectionStyle = .none
        cell.reviewLabel?.text = NSLocalizedString("Reviews", comment: "Reviews descriptive label")

        cell.reviewTotalsLabel?.applySecondaryBodyStyle()
        // 🖐🏼 I solemnly swear I'm not converting currency values to a Double.
        let ratingCount = Double(product.ratingCount)
        cell.reviewTotalsLabel?.text = ratingCount.humanReadableString()
        let averageRating = Double(product.averageRating)
        cell.starRatingView.rating = CGFloat(averageRating ?? 0)
    }

    func configurePermalink(_ cell: WooBasicTableViewCell) {
        cell.textLabel?.text = NSLocalizedString("View product on store", comment: "The descriptive label. Tapping the row will open the product's page in a web view.")
        cell.accessoryImage = Gridicon.iconOfType(.external)
    }

    func configureAffiliateLink(_ cell: WooBasicTableViewCell) {
        cell.textLabel?.text = NSLocalizedString("View affiliate product", comment: "The descriptive label. Tapping the row will open the affliate product's link in a web view.")
        cell.accessoryImage = Gridicon.iconOfType(.external)
    }

    func configurePrice(_ cell: TitleBodyTableViewCell) {
        cell.titleLabel?.text = NSLocalizedString("Price", comment: "Product Details > Pricing and Inventory section > descriptive label for the Price cell.")

        // determine if a `regular_price` exists.

        // if yes, then display Regular Price: / Sale Price: w/ currency formatting

        // if no, then display the `price` w/ no prefix and w/ currency formatting
    }

    func configureInventory(_ cell: TitleBodyTableViewCell) {

    }

    func configureSku(_ cell: TitleBodyTableViewCell) {

    }

    func configureAffiliateInventory(_ cell: TitleBodyTableViewCell) {

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
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch rowAtIndexPath(indexPath) {
        case .productSummary:
            return productHasImage ? Metrics.productImageHeight : Metrics.emptyProductImageHeight
        default:
            return UITableView.automaticDimension
        }
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
}


// MARK: - UITableViewDelegate Conformance
//
extension ProductDetailsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rowAtIndexPath(indexPath) {
        case .permalink:
            if let url = URL(string: product.permalink) {
                UIApplication.shared.open(url)
            }
        case .affiliateLink:
            if let externalUrlString = product.externalURL,
                let url = URL(string: externalUrlString) {
                UIApplication.shared.open(url)
            }
        default:
            break
        }
    }
}


// MARK: - Tableview helpers
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

    /// Rebuild the section struct
    ///
    func reloadSections() {
        var rows: [Row] = [.productSummary, .productName]
        var customContent = [Row]()

        switch product.productType {
        case .simple:
            customContent = [.totalOrders, .reviews, .permalink]
        case .grouped:
            customContent = [.totalOrders, .reviews, .permalink]
        case .affiliate:
            customContent = [.totalOrders, .reviews, .permalink, .affiliateLink]
        case .variable:
            customContent = [.totalOrders, .reviews, .permalink]
        case .custom(_):
            customContent = [.totalOrders, .reviews, .permalink]
        }

        rows.append(contentsOf: customContent)

        let summary = Section(rows: rows)
        sections = [summary].compactMap { $0 }
    }
}


// MARK: - Constants
//
private extension ProductDetailsViewController {

    enum Metrics {
        static let estimatedRowHeight = CGFloat(86)
        static let sectionHeight = CGFloat(44)
        static let productImageHeight = CGFloat(374)
        static let emptyProductImageHeight = CGFloat(86)
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

    /// Rows are organized in the order they appear in the UI
    ///
    enum Row {
        case productSummary
        case productName
        case totalOrders
        case reviews
        case permalink
        case affiliateLink
        case price
        case inventory
        case sku
        case affiliateInventory

        var reuseIdentifier: String {
            switch self {
            case .productSummary:
                return LargeImageTableViewCell.reuseIdentifier
            case .productName:
                return TitleBodyTableViewCell.reuseIdentifier
            case .totalOrders:
                return TwoColumnTableViewCell.reuseIdentifier
            case .reviews:
                return ProductReviewsTableViewCell.reuseIdentifier
            case .permalink:
                return WooBasicTableViewCell.reuseIdentifier
            case .affiliateLink:
                return WooBasicTableViewCell.reuseIdentifier
            case .price:
                return TitleBodyTableViewCell.reuseIdentifier
            case .inventory:
                return TitleBodyTableViewCell.reuseIdentifier
            case .sku:
                return TitleBodyTableViewCell.reuseIdentifier
            case .affiliateInventory:
                return TitleBodyTableViewCell.reuseIdentifier
            }
        }
    }
}
