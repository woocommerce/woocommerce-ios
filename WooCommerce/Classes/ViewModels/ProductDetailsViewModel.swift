import Foundation
import Yosemite
import UIKit
import Gridicons


// MARK: - Product details view model
//
final class ProductDetailsViewModel {

    /// Closures
    ///
    var onError: (() -> Void)?
    var onReload: (() -> Void)?

    /// Yosemite.Product
    ///
    var product: Product {
        didSet {
            reloadTableViewSectionsAndData()
        }
    }

    /// Nav bar title
    ///
    var title: String {
        return product.name
    }

    /// Product ID
    ///
    var productID: Int {
        return product.productID
    }

    /// Sections to be rendered
    ///
    private(set) var sections = [Section]()

    /// EntityListener: Update / Deletion Notifications.
    ///
    private lazy var entityListener: EntityListener<Product> = {
        return EntityListener(storageManager: AppDelegate.shared.storageManager,
                              readOnlyEntity: product)
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

    /// Product image height.
    ///
    private var productImageHeight: CGFloat {
        return productHasImage ? Metrics.productImageHeight : Metrics.emptyProductImageHeight
    }

    /// Table section height.
    ///
    var sectionHeight: CGFloat {
        return Metrics.sectionHeight
    }

    /// Table row height
    ///
    var rowHeight: CGFloat {
        return Metrics.estimatedRowHeight
    }

    /// Currency Formatter
    ///
    private var currencyFormatter = CurrencyFormatter()


    // MARK: - Intializers

    /// Designated initializer.
    ///
    init(product: Product) {
        self.product = product
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

            self.onError?()
        }
    }
}


// MARK: - Table data conformance
//
extension ProductDetailsViewModel {

    func numberOfSections() -> Int {
        return sections.count
    }

    func numberOfRowsInSection(_ section: Int) -> Int {
        return sections[section].rows.count
    }

    func heightForRow(at indexPath: IndexPath) -> CGFloat {
        switch rowAtIndexPath(indexPath) {
        case .productSummary:
            return productImageHeight
        default:
            return UITableView.automaticDimension
        }
    }

    func heightForHeader(in section: Int) -> CGFloat {
        if sections[section].title == nil {
            // iOS 11 table bug. Must return a tiny value to collapse `nil` or `empty` section headers.
            return .leastNonzeroMagnitude
        }

        return UITableView.automaticDimension
    }

    func heightForFooter(in section: Int) -> CGFloat {
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

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }

    // MARK: - Configure cells

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
            let size = CGSize(width: cell.frame.width, height: Metrics.emptyProductImageHeight)
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
        cell.bodyLabel?.text = product.name
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
        cell.bodyLabel?.text = NSLocalizedString("View product on store", comment: "The descriptive label. Tapping the row will open the product's page in a web view.")
        cell.accessoryImage = Gridicon.iconOfType(.external)
    }

    func configureAffiliateLink(_ cell: WooBasicTableViewCell) {
        cell.bodyLabel?.text = NSLocalizedString("View affiliate product", comment: "The descriptive label. Tapping the row will open the affliate product's link in a web view.")
        cell.accessoryImage = Gridicon.iconOfType(.external)
    }

    func configurePrice(_ cell: TitleBodyTableViewCell) {
        cell.titleLabel?.text = NSLocalizedString("Price", comment: "Product Details > Pricing and Inventory section > descriptive label for the Price cell.")

        if let regularPrice = product.regularPrice, !regularPrice.isEmpty,
            let salePrice = product.salePrice, !salePrice.isEmpty {
            let regularPricePrefix = NSLocalizedString("Regular price:", comment: "A descriptive label prefix. Example: 'Regular price: $20.00'")
            let regularPriceFormatted = currencyFormatter.formatAmount(regularPrice) ?? ""
            let bodyText = regularPricePrefix + " " + regularPriceFormatted

            let salePricePrefix = NSLocalizedString("Sale price:", comment: "A descriptive label prefix. Example: 'Sale price: $18.00'")
            let salePriceFormatted = currencyFormatter.formatAmount(salePrice) ?? ""
            let secondLineText = salePricePrefix + " " + salePriceFormatted

            cell.bodyLabel?.text = bodyText + "\n" + secondLineText
        } else if !product.price.isEmpty {
            cell.bodyLabel?.text = currencyFormatter.formatAmount(product.price) ?? ""
        }
    }

    func configureInventory(_ cell: TitleBodyTableViewCell) {
        cell.titleLabel?.text = NSLocalizedString("Inventory", comment: "Product Details > Pricing and Inventory section > descriptive label for the Inventory cell.")

        guard product.manageStock else {
            let stockStatusPrefix = NSLocalizedString("Stock status:", comment: "A descriptive label prefix. Example: 'Stock status: In stock'")
            let stockStatus = product.productStockStatus.description
            var bodyText = stockStatusPrefix + " " + stockStatus

            if let sku = product.sku,
                !sku.isEmpty {
                let skuPrefix = NSLocalizedString("SKU:", comment: "A descriptive label prefix. Example: 'SKU: woo-virtual-beanie'")
                bodyText += "\n" + skuPrefix + " " + sku
            }

            cell.bodyLabel?.text = bodyText
            return
        }

        var bodyText = ""
        if let stockQuantity = product.stockQuantity {
            let stockQuantityPrefix = NSLocalizedString("Stock quantity:", comment: "A descriptive label prefix. Example: 'Stock quantity: 19'")
            let stockText = stockQuantityPrefix + " " + String(stockQuantity)
            bodyText += stockText + "\n"
        }

        var backordersText = ""
        let backordersPrefix = NSLocalizedString("Backorders:", comment: "A descriptive label prefix. Example: 'Backorders: not allowed'")
        let allowed = NSLocalizedString("allowed", comment: "Backorders status. Example: 'Backorders: allowed'")
        let notAllowed = NSLocalizedString("not allowed", comment: "Backorders status. Example: 'Backorders: not allowed'")
        let backordersSuffix = product.backordersAllowed ? allowed : notAllowed
        backordersText = backordersPrefix + " " + backordersSuffix
        bodyText += backordersText

        if let sku = product.sku,
            !sku.isEmpty {
            let skuPrefix = NSLocalizedString("SKU:", comment: "A descriptive label prefix. Example: 'SKU: woo-virtual-beanie'")
            bodyText += "\n" + skuPrefix + " " + sku
        }

        cell.bodyLabel?.text = bodyText
    }

    func configureSku(_ cell: TitleBodyTableViewCell) {
        let title = NSLocalizedString("SKU", comment: "A descriptive title for the SKU cell in Product Details > Inventory, for Grouped products.")
        if let sku = product.sku,
            !sku.isEmpty {
            cell.bodyLabel?.text = sku
        }
        cell.titleLabel?.text = title
    }

    func configureAffiliateInventory(_ cell: TitleBodyTableViewCell) {
        let title = NSLocalizedString("Inventory", comment: "Product Details > Pricing & Inventory > Inventory cell title")
        cell.titleLabel?.text = title

        let skuPrefix = NSLocalizedString("SKU:", comment: "A descriptive label for the SKU prefix. Example: 'SKU: woo-affiliate-beanie'")
        if let sku = product.sku,
            !sku.isEmpty {
            cell.bodyLabel?.text = skuPrefix + " " + sku
        } else {
            cell.bodyLabel?.text = nil
        }
    }

    // MARK: - Table data retrieval methods

    /// Returns the Row enum value for the provided IndexPath
    ///
    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    /// Reloads the tableView's sections and data.
    ///
    func reloadTableViewSectionsAndData() {
        reloadSections()
        onReload?()
    }

    /// Rebuild the section struct
    ///
    func reloadSections() {
        let summary = configureSummary()
        let pricingAndInventory = configurePricingAndInventory()
        sections = [summary, pricingAndInventory].compactMap { $0 }
    }

    /// Summary section.
    ///
    func configureSummary() -> Section {
        var rows: [Row] = [.productSummary, .productName, .totalOrders, .reviews, .permalink]

        if product.productType == .affiliate {
            rows.append(.affiliateLink)
        }

        return Section(rows: rows)
    }

    /// Pricing and Inventory Section.
    ///
    func configurePricingAndInventory() -> Section {
        if product.productType == .grouped {
            let title = NSLocalizedString("Inventory", comment: "Product Details - inventory section title")
            let row: Row = .sku

            return Section(title: title, rightTitle: nil, footer: nil, row: row)
        }

        let title = NSLocalizedString("Pricing and Inventory", comment: "Product Details - pricing and inventory section title")
        var rows: [Row] = [.price]

        if product.productType == .affiliate {
            rows.append(.affiliateInventory)
        } else {
            rows.append(.inventory)
        }

        return Section(title: title, rightTitle: nil, footer: nil, rows: rows)
    }
}


// MARK: - Table delegate conformance
//
extension ProductDetailsViewModel {
    func didSelectRow(at indexPath: IndexPath, sender: UIViewController) {
        switch rowAtIndexPath(indexPath) {
        case .permalink:
            WebviewHelper.launch(product.permalink, with: sender)
        case .affiliateLink:
            WebviewHelper.launch(product.externalURL, with: sender)
        default:
            break
        }
    }
}

// MARK: - Syncing Helpers
//
extension ProductDetailsViewModel {

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


// MARK: - Constants
//
extension ProductDetailsViewModel {

    /// Table sections struct
    ///
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

    /// Table rows are organized in the order they appear in the UI
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

    /// Table measurements
    ///
    enum Metrics {
        static let estimatedRowHeight = CGFloat(86)
        static let sectionHeight = CGFloat(44)
        static let productImageHeight = CGFloat(374)
        static let emptyProductImageHeight = CGFloat(86)
    }
}
