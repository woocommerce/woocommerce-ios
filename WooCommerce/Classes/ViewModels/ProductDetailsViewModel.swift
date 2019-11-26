import Foundation
import Yosemite
import UIKit
import Gridicons
import WordPressShared


// MARK: - Product details view model
//
final class ProductDetailsViewModel {

    // MARK: - public variables

    /// Closures
    ///
    var onError: (() -> Void)?
    var onReload: (() -> Void)?
    var onPurchaseNoteTapped: (() -> Void)?

    /// Yosemite.Product
    ///
    var product: Product {
        didSet {
            reloadTableViewSectionsAndData()
        }
    }

    /// Yosemite.Order.currency
    ///
    let currency: String

    /// Nav bar title
    ///
    var title: String {
        return product.name
    }

    /// Purchase Note
    /// - stripped of HTML
    /// - no ending newline character
    /// - cannot be a lazy var because it's a computed property
    ///
    var cleanedPurchaseNote: String? {
        guard let noHTMLString = product.purchaseNote?.strippedHTML else {
            return nil
        }
        let cleanedString = String.stripLastNewline(in: noHTMLString)

        return cleanedString
    }

    /// Product ID
    ///
    var productID: Int {
        return product.productID
    }

    // MARK: - private variables

    /// Sections to be rendered
    ///
    private(set) var sections = [Section]()

    /// EntityListener: Update / Deletion Notifications.
    ///
    private lazy var entityListener: EntityListener<Product> = {
        return EntityListener(storageManager: ServiceLocator.storageManager,
                              readOnlyEntity: product)
    }()

    /// ResultsController for `WC > Settings > Products > General` from the site.
    ///
    private lazy var resultsController: ResultsController<StorageSiteSetting> = {
        let storageManager = ServiceLocator.storageManager

        let sitePredicate = NSPredicate(format: "siteID == %lld", ServiceLocator.stores.sessionManager.defaultStoreID ?? Int.min)
        let settingTypePredicate = NSPredicate(format: "settingGroupKey ==[c] %@", SiteSettingGroup.product.rawValue)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sitePredicate, settingTypePredicate])

        let descriptor = NSSortDescriptor(keyPath: \StorageSiteSetting.siteID, ascending: false)

        return ResultsController<StorageSiteSetting>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Yosemite.SiteSetting
    ///
    var productSettings: [SiteSetting] {
        return resultsController.fetchedObjects
    }

    /// Weight unit.
    ///
    var weightUnit: String?

    /// Dimension unit.
    ///
    var dimensionUnit: String?

    /// Table section height.
    ///
    var sectionHeight: CGFloat {
        return Metrics.sectionHeight
    }

    /// Table row height.
    ///
    var rowHeight: CGFloat {
        return Metrics.estimatedRowHeight
    }

    /// Currency Formatter.
    ///
    private var currencyFormatter = CurrencyFormatter()


    // MARK: - Intializers

    /// Designated initializer.
    ///
    init(product: Product, currency: String) {
        self.product = product
        self.currency = currency

        refreshResultsController()
    }

    /// Setup: EntityListener.
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

    /// Setup: Results Controller.
    ///
    func refreshResultsController() {
        try? resultsController.performFetch()

        // After refreshing the results controller,
        // let's look up some product settings it holds.
        weightUnit = lookupProductSettings(Keys.weightUnit)
        dimensionUnit = lookupProductSettings(Keys.dimensionUnit)
    }

    /// Look up Product Settings
    ///
    func lookupProductSettings(_ settingID: String) -> String? {
        return productSettings.filter({$0.settingID == settingID}).first?.value
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
        default:
            return UITableView.automaticDimension
        }
    }

    func heightForHeader(in section: Int) -> CGFloat {
        if sections[section].title == nil {
            // iOS 11 table bug.
            // Must return a tiny value to collapse `nil` or `empty` section headers.
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
        case let cell as ProductImagesHeaderTableViewCell:
            configureProductImages(cell)
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
        case let cell as TitleBodyTableViewCell where row == .productVariants:
            configureProductVariants(cell)
        case let cell as TitleBodyTableViewCell where row == .price:
            configurePrice(cell)
        case let cell as TitleBodyTableViewCell where row == .inventory:
            configureInventory(cell)
        case let cell as TitleBodyTableViewCell where row == .sku:
            configureSku(cell)
        case let cell as TitleBodyTableViewCell where row == .affiliateInventory:
            configureAffiliateInventory(cell)
        case let cell as TitleBodyTableViewCell where row == .shipping:
            configureShipping(cell)
        case let cell as TitleBodyTableViewCell where row == .downloads:
            configureDownloads(cell)
        case let cell as ReadMoreTableViewCell:
            configurePurchaseNote(cell)
        default:
            fatalError("Unidentified row type")
        }
    }

    /// Product Images cell.
    ///
    func configureProductImages(_ cell: ProductImagesHeaderTableViewCell) {
        cell.configure(with: product, config: .images)
        cell.onImageSelected = {[weak self] (productImage, indexPath) in
            print("OnImageSelected")
        }
        cell.onAddImage = { [weak self] in
            print("OnAddImage")
        }
//        if productHasImage {
//            cell.heightConstraint.constant = Metrics.productImageHeight
//            mainImageView.downloadImage(from: imageURL, placeholderImage: UIImage.productPlaceholderImage)
//        }
//
//        if product.productStatus != .publish {
//            cell.textBadge?.applyPaddedLabelSubheadStyles()
//            cell.textBadge?.layer.backgroundColor = StyleManager.defaultTextColor.cgColor
//            cell.textBadge?.textColor = StyleManager.wooWhite
//            cell.textBadge?.text = product.productStatus.description
//        }
    }

    /// Product Title cell.
    ///
    func configureProductName(_ cell: TitleBodyTableViewCell) {
        cell.accessoryType = .none
        cell.selectionStyle = .none
        cell.titleLabel?.text = NSLocalizedString("Title",
                                                  comment: "Product details screen — product title descriptive label")
        cell.bodyLabel?.text = product.name
    }

    /// Total Orders cell.
    ///
    func configureTotalOrders(_ cell: TwoColumnTableViewCell) {
        cell.selectionStyle = .none
        cell.leftLabel?.text = NSLocalizedString("Total Orders",
                                                 comment: "Product details screen - total orders descriptive label")
        cell.rightLabel?.applySecondaryBodyStyle()
        cell.rightLabel.textInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        cell.rightLabel?.text = String(product.totalSales)
    }

    /// Reviews cell.
    ///
    func configureReviews(_ cell: ProductReviewsTableViewCell) {
        cell.selectionStyle = .none
        cell.reviewLabel?.text = NSLocalizedString("Reviews",
                                                   comment: "Reviews descriptive label")

        cell.reviewTotalsLabel?.applySecondaryBodyStyle()
        // 🖐🏼 I solemnly swear I'm not converting currency values to a Double.
        let ratingCount = Double(product.ratingCount)
        cell.reviewTotalsLabel?.text = ratingCount.humanReadableString()
        let averageRating = Double(product.averageRating)
        cell.starRatingView.rating = CGFloat(averageRating ?? 0)
    }

    /// Product permalink cell.
    ///
    func configurePermalink(_ cell: WooBasicTableViewCell) {
        cell.bodyLabel?.text = NSLocalizedString("View product on store",
                                                 comment: "The descriptive label. Tapping the row will open the product's page in a web view.")
        cell.accessoryImage = .externalImage
    }

    /// Affiliate (External) link cell.
    ///
    func configureAffiliateLink(_ cell: WooBasicTableViewCell) {
        cell.bodyLabel?.text = NSLocalizedString("View affiliate product",
                                                 comment: "The descriptive label. Tapping the row will open the affliate product's link in a web view.")
        cell.accessoryImage = .externalImage
    }

    /// Product variants cell.
    ///
    func configureProductVariants(_ cell: TitleBodyTableViewCell) {
        cell.titleLabel?.text = NSLocalizedString("Variants", comment: "Product Details > descriptive label for the Product Variants cell.")

        let attributes = product.attributes

        let format = NSLocalizedString("%1$@ (%2$ld options)", comment: "Format for each Product attribute")
        let bodyText = attributes
            .map({ String.localizedStringWithFormat(format, $0.name, $0.options.count) })
            .joined(separator: "\n")
        cell.bodyLabel.text = bodyText

        cell.accessoryType = .disclosureIndicator
    }

    /// Price cell.
    ///
    func configurePrice(_ cell: TitleBodyTableViewCell) {
        cell.titleLabel?.text = NSLocalizedString("Price",
                                                  comment: "Product Details > Pricing and Inventory section > descriptive label for the Price cell.")

        if let regularPrice = product.regularPrice, !regularPrice.isEmpty,
            let salePrice = product.salePrice, !salePrice.isEmpty {
            let regularPricePrefix = NSLocalizedString("Regular price:",
                                                       comment: "A descriptive label prefix. Example: 'Regular price: $20.00'")

            let regularPriceFormatted = currencyFormatter.formatAmount(regularPrice, with: currency) ?? String()
            let bodyText = regularPricePrefix + " " + regularPriceFormatted

            let salePricePrefix = NSLocalizedString("Sale price:",
                                                    comment: "A descriptive label prefix. Example: 'Sale price: $18.00'")
            let salePriceFormatted = currencyFormatter.formatAmount(salePrice, with: currency) ?? String()
            let secondLineText = salePricePrefix + " " + salePriceFormatted

            cell.bodyLabel?.text = bodyText + "\n" + secondLineText
        } else {
            cell.bodyLabel?.text = product.price.isEmpty ? "--" : currencyFormatter.formatAmount(product.price, with: currency)
        }
    }

    /// Inventory cell.
    ///
    func configureInventory(_ cell: TitleBodyTableViewCell) {
        cell.titleLabel?.text = NSLocalizedString("Inventory",
                                                  comment: "Product Details > Pricing and Inventory section > descriptive label for the Inventory cell.")

        guard product.manageStock else {
            let stockStatusPrefix = NSLocalizedString("Stock status:",
                                                      comment: "A descriptive label prefix. Example: 'Stock status: In stock'")
            let stockStatus = product.productStockStatus.description
            var bodyText = stockStatusPrefix + " " + stockStatus

            if let sku = product.sku,
                !sku.isEmpty {
                let skuPrefix = NSLocalizedString("SKU:",
                                                  comment: "A descriptive label prefix. Example: 'SKU: woo-virtual-beanie'")
                bodyText += "\n" + skuPrefix + " " + sku
            }

            cell.bodyLabel?.text = bodyText
            return
        }

        var bodyText = ""
        if let stockQuantity = product.stockQuantity {
            let stockQuantityPrefix = NSLocalizedString("Stock quantity:",
                                                        comment: "A descriptive label prefix. Example: 'Stock quantity: 19'")
            let stockText = stockQuantityPrefix + " " + String(stockQuantity)
            bodyText += stockText + "\n"
        }

        var backordersText = ""
        let backordersPrefix = NSLocalizedString("Backorders:",
                                                 comment: "A descriptive label prefix. Example: 'Backorders: not allowed'")
        let allowed = NSLocalizedString("allowed",
                                        comment: "Backorders status. Example: 'Backorders: allowed'")
        let notAllowed = NSLocalizedString("not allowed",
                                           comment: "Backorders status. Example: 'Backorders: not allowed'")
        let backordersSuffix = product.backordersAllowed ? allowed : notAllowed
        backordersText = backordersPrefix + " " + backordersSuffix
        bodyText += backordersText

        if let sku = product.sku,
            !sku.isEmpty {
            let skuPrefix = NSLocalizedString("SKU:",
                                              comment: "A descriptive label prefix. Example: 'SKU: woo-virtual-beanie'")
            bodyText += "\n" + skuPrefix + " " + sku
        }

        cell.bodyLabel?.text = bodyText
    }

    /// SKU cell.
    ///
    func configureSku(_ cell: TitleBodyTableViewCell) {
        let title = NSLocalizedString("SKU",
                                      comment: "A descriptive title for the SKU cell in Product Details > Inventory, for Grouped products.")
        if let sku = product.sku,
            !sku.isEmpty {
            cell.bodyLabel?.text = sku
        }
        cell.titleLabel?.text = title
    }

    /// Affiliate Inventory cell.
    ///
    func configureAffiliateInventory(_ cell: TitleBodyTableViewCell) {
        let title = NSLocalizedString("Inventory",
                                      comment: "Product Details > Pricing & Inventory > Inventory cell title")
        cell.titleLabel?.text = title

        let skuPrefix = NSLocalizedString("SKU:",
                                          comment: "A descriptive label for the SKU prefix. Example: 'SKU: woo-affiliate-beanie'")
        if let sku = product.sku,
            !sku.isEmpty {
            cell.bodyLabel?.text = skuPrefix + " " + sku
        } else {
            cell.bodyLabel?.text = nil
        }
    }

    /// Shipping cell.
    ///
    func configureShipping(_ cell: TitleBodyTableViewCell) {
        let title = NSLocalizedString("Shipping",
                                      comment: "Product Details > Purchase Details > Shipping cell title")
        var bodyText = ""

        // first line - weight
        let weightPrefix = NSLocalizedString("Weight:",
                                            comment: "Label prefix. Example: 'Weight: 1kg'")
        let weightAmount = product.weight ?? ""
        let wUnit = weightUnit ?? ""
        let weightText = weightPrefix + " " + weightAmount + wUnit

        // second line - dimensions
        let sizePrefix = NSLocalizedString("Size:",
                                           comment: "Label prefix. Example: 'Size: 8 x 10 x 10 cm'")
        let length = product.dimensions.length
        let width = product.dimensions.width
        let height = product.dimensions.height
        let dimensions = length + " × " + width + " × " + height
        let sizeUnit = dimensionUnit ?? ""
        let sizeText = sizePrefix + " " + dimensions + " " + sizeUnit

        bodyText = weightText + "\n" + sizeText

        // third line - shipping class
        if let shippingClass = product.shippingClass,
            !shippingClass.isEmpty {
            let shippingClassPrefix = NSLocalizedString("Shipping class:",
                                                        comment: "Label prefix. Example: 'Shipping class: Free Shipping'")
            let shippingClassText = "\n" + shippingClassPrefix + " " + shippingClass
            bodyText += shippingClassText
        }

        cell.titleLabel.text = title
        cell.bodyLabel.text = bodyText
    }

    /// Downloads cell.
    ///
    func configureDownloads(_ cell: TitleBodyTableViewCell) {
        // Number of files line
        let numberOfFilesPrefix = NSLocalizedString("Number of files:",
                                                    comment: "Label prefix. Example: 'Number of files: 2'")
        let fileCount = String(product.downloads.count)
        let numberOfFilesText = numberOfFilesPrefix + " " + fileCount

        // Limits line
        let limitSingular = NSLocalizedString("Limit: %ld download",
                                              comment: "'Limit: 1 download', for example.")
        let limitPlural = NSLocalizedString("Limit: %ld downloads",
                                            comment: "'Limit: 2 downloads', for example.")
        let limitText = String.pluralize(product.downloadLimit,
                                         singular: limitSingular,
                                         plural: limitPlural)

        // Downloads expiration line
        let expirationSingular = NSLocalizedString("Expiry: %ld day", comment: "Expiry: 1 day")
        let expirationPlural = NSLocalizedString("Expiry: %ld days",
                                                 comment: "For example: 'Expiry: 30 days'")
        let expirationText = String.pluralize(product.downloadExpiry,
                                              singular: expirationSingular,
                                              plural: expirationPlural)

        // Full text for cell labels
        let title = NSLocalizedString("Downloads",
                                      comment: "Product Details > Purchase Details > Downloads cell title")
        let bodyText = numberOfFilesText + "\n" + limitText + "\n" + expirationText
        cell.titleLabel?.text = title
        cell.bodyLabel?.text = bodyText
    }

    /// Purchase Note cell.
    ///
    func configurePurchaseNote(_ cell: ReadMoreTableViewCell) {
        cell.titleLabel?.text = NSLocalizedString("Purchase note",
                                                  comment: "Product Details > Purchase Details > Purchase note cell title")

        cell.bodyLabel?.text = cleanedPurchaseNote

        let readMoreTitle = NSLocalizedString("Read more",
                                              comment: "Read more of the purchase note. Only the first two lines of text are displayed.")

        cell.moreButton?.setTitle(readMoreTitle, for: .normal)
        cell.onMoreTouchUp = { [weak self] in
            self?.onPurchaseNoteTapped?()
        }
    }


    // MARK: - Table helper methods

    /// Check if all prices are undefined.
    ///
    func allPricesEmpty() -> Bool {
        let price = product.price
        let regularPrice = product.regularPrice ?? ""
        let salePrice = product.salePrice ?? ""

        return price.isEmpty && regularPrice.isEmpty && salePrice.isEmpty
    }

    // MARK: - Table data retrieval methods

    /// Returns the Row enum value for the provided IndexPath.
    ///
    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    /// Reloads the tableView's sections and data.
    ///
    func reloadTableViewSectionsAndData() {
        refreshResultsController()
        reloadSections()
        onReload?()
    }

    /// Rebuild the section struct.
    ///
    func reloadSections() {
        let photo = configureProductImages()
        let summary = configureSummary()
        let pricingAndInventory = configurePricingAndInventory()
        let purchaseDetails = configurePurchaseDetails()
        sections = [photo, summary, pricingAndInventory, purchaseDetails].compactMap { $0 }
    }

    /// Product Images section
    ///
    func configureProductImages() -> Section? {
        return Section(row: .productImages)
    }

    /// Summary section.
    ///
    func configureSummary() -> Section {
        if product.productType == .affiliate {
            let affiliateRows: [Row] = [.productName, .reviews, .permalink, .affiliateLink]
            return Section(rows: affiliateRows)
        }

        let rows: [Row]
        if shouldShowProductVariantsInfo() {
            rows = [.productName, .totalOrders, .reviews, .productVariants, .permalink]
        } else {
            rows = [.productName, .totalOrders, .reviews, .permalink]
        }

        return Section(rows: rows)
    }

    /// Pricing and Inventory Section.
    ///
    func configurePricingAndInventory() -> Section? {
        guard shouldShowProductVariantsInfo() == false else {
            return nil
        }

        // For grouped products
        if product.productType == .grouped {
            return groupedProductInventorySection()
        }

        // For non-grouped products that have no prices defined.
        if allPricesEmpty() == true {
            return nonGroupedInventorySection()
        }

        // For non-grouped products that contain at least one price.
        return pricesAndInventorySection()
    }

    /// Purchase Details Section.
    ///
    func configurePurchaseDetails() -> Section? {
        let title = NSLocalizedString("Purchase Details",
                                      comment: "Product Details - purchase details section title")
        switch product.productType {
        case .simple, .variable, .custom:
            var rows = [Row]()

            // downloadable and a download is specified
            if product.downloadable && product.downloads.count > 0 {
                rows.append(.downloads)
            }

            // is not a download,
            // and ship weight exists,
            // and dimension width exists
            if product.downloadable == false
                && product.weight != nil
                && !product.dimensions.width.isEmpty {
                rows.append(.shipping)
            }

            // has a product note
            if let purchaseNote = product.purchaseNote,
                !purchaseNote.isEmpty {
                rows.append(.purchaseNote)
            }

            // don't create this section if there are no rows
            if rows.count == 0 {
                return nil
            }

            return Section(title: title, rows: rows)

        case .affiliate, .grouped:
            return nil
        }
    }

    /// Grouped products.
    /// Builds the Inventory section with no price cells.
    ///
    func groupedProductInventorySection() -> Section {
        let title = NSLocalizedString("Inventory",
                                      comment: "Product Details - inventory section title")
        let row: Row = .sku

        return Section(title: title, row: row)
    }

    /// Non-grouped products, no prices defined.
    /// Builds the non-grouped Inventory section with no price cells.
    ///
    func nonGroupedInventorySection() -> Section {
        let title = NSLocalizedString("Inventory",
                                      comment: "Product Details - inventory section title")
        if product.productType == .affiliate {
            return Section(title: title, row: .affiliateInventory)
        }

        return Section(title: title, row: .inventory)
    }

    /// Non-grouped products that have at least one price defined.
    /// Builds the Pricing and Inventory cells.
    ///
    func pricesAndInventorySection() -> Section {
        let title = NSLocalizedString("Pricing and Inventory",
                                      comment: "Product Details - pricing and inventory section title")
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
        case .productVariants:
            ServiceLocator.analytics.track(.productDetailsProductVariantsTapped)
            let variationsViewController = ProductVariationsViewController(siteID: Int64(product.siteID),
                                                                           productID: Int64(product.productID))
            sender.navigationController?.pushViewController(variationsViewController, animated: true)
        default:
            break
        }
    }
}

// MARK: - Syncing Helpers
//
extension ProductDetailsViewModel {

    func syncProduct(onCompletion: ((Error?) -> ())? = nil) {
        let action = ProductAction.retrieveProduct(siteID: product.siteID,
                                                   productID: product.productID) { [weak self] (product, error) in
            guard let self = self, let product = product else {
                DDLogError("⛔️ Error synchronizing Product: \(error.debugDescription)")
                onCompletion?(error)
                return
            }

            self.product = product
            onCompletion?(nil)
        }

        ServiceLocator.stores.dispatch(action)
    }
}


// MARK: - Variants Helpers
//
private extension ProductDetailsViewModel {
    func shouldShowProductVariantsInfo() -> Bool {
        let isFeatureEnabled = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.readonlyProductVariants)
        let hasVariations = product.variations.isEmpty == false
        return isFeatureEnabled && hasVariations
    }
}


// MARK: - Constants
//
extension ProductDetailsViewModel {

    /// Table sections struct.
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

    /// Table rows are organized in the order they appear in the UI.
    ///
    enum Row {
        case productImages
        case productName
        case totalOrders
        case reviews
        case productVariants
        case permalink
        case affiliateLink
        case price
        case inventory
        case sku
        case affiliateInventory
        case shipping
        case downloads
        case purchaseNote

        var reuseIdentifier: String {
            switch self {
            case .productImages:
                return ProductImagesHeaderTableViewCell.reuseIdentifier
            case .productName:
                return TitleBodyTableViewCell.reuseIdentifier
            case .totalOrders:
                return TwoColumnTableViewCell.reuseIdentifier
            case .reviews:
                return ProductReviewsTableViewCell.reuseIdentifier
            case .productVariants:
                return TitleBodyTableViewCell.reuseIdentifier
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
            case .shipping:
                return TitleBodyTableViewCell.reuseIdentifier
            case .downloads:
                return TitleBodyTableViewCell.reuseIdentifier
            case .purchaseNote:
                return ReadMoreTableViewCell.reuseIdentifier
            }
        }
    }

    /// Table measurements.
    ///
    enum Metrics {
        static let estimatedRowHeight = CGFloat(86)
        static let sectionHeight = CGFloat(44)
    }

    enum Keys {
        static let weightUnit = "woocommerce_weight_unit"
        static let dimensionUnit = "woocommerce_dimension_unit"
    }
}
