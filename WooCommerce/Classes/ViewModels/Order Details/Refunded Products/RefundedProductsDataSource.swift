import Foundation
import UIKit
import Yosemite
import protocol Storage.StorageManagerType


/// The main file for Refunded Products data.
/// Must conform to NSObject so it can be the UITableViewDataSource.
///
final class RefundedProductsDataSource: NSObject {
    /// Aggregate data for refunded products
    ///
    private(set) var refundedProducts: [AggregateOrderItem]

    /// Order
    ///
    private(set) var order: Order

    /// Sections to be rendered
    ///
    private(set) var sections = [Section]()

    private let storageManager: StorageManagerType

    /// Designated initializer.
    ///
    init(order: Order,
         refundedProducts: [AggregateOrderItem],
         storageManager: StorageManagerType) {
        self.order = order
        self.refundedProducts = refundedProducts
        self.storageManager = storageManager
    }

    /// The results controllers used to display a refund
    ///
    private lazy var resultsControllers: RefundDetailsResultController = {
        return RefundDetailsResultController(siteID: order.siteID,
                                             variationIDs: refundedProducts.map(\.variationID).filter { $0 != 0 },
                                             storageManager: storageManager)
    }()

    /// Set up results controllers
    ///
    func configureResultsControllers(onReload: @escaping () -> Void) {
        resultsControllers.configureResultsControllers(onReload: onReload)
    }

    /// Update the data source's order when notified
    ///
    func update(order: Order) {
        self.order = order
    }

    /// Products from a Refund
    ///
    var products: [OrderDetailsProduct] {
        return resultsControllers.products
    }

    /// ProductVariations from a Refund
    ///
    var productVariations: [ProductVariation] {
        return resultsControllers.productVariations
    }
}


// MARK: - Conformance to UITableViewDataSource
//
extension RefundedProductsDataSource: UITableViewDataSource {
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
}


// MARK: - Support for UITableViewDelegate
//
extension RefundedProductsDataSource {
    /// Set up table section headings
    ///
    func viewForHeaderInSection(_ section: Int, tableView: UITableView) -> UIView? {
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


// MARK: - Support for UITableViewDataSource
//
private extension RefundedProductsDataSource {
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as ProductDetailsTableViewCell where row == .orderItemRefunded:
            configureRefundedProduct(cell, at: indexPath)
        default:
            fatalError("Unidentified customer info row type")
        }
    }

    /// Setup: Refunded product details cell
    ///
    func configureRefundedProduct(_ cell: ProductDetailsTableViewCell, at indexPath: IndexPath) {
        let refundedProduct = refundedProducts[indexPath.row]
        let product = lookUpProduct(by: refundedProduct.productID)
        let isChildWithParent = AggregateDataHelper.isChildItemWithParent(refundedProduct, in: refundedProducts)
        let refundedProductViewModel = ProductDetailsCellViewModel(aggregateItem: refundedProduct.copy(imageURL: imageURL(for: refundedProduct)),
                                                                   currency: order.currency,
                                                                   product: product,
                                                                   hasAddOns: false,
                                                                   isChildWithParent: isChildWithParent)
        let imageService = ServiceLocator.imageService

        cell.selectionStyle = .default
        cell.configure(item: refundedProductViewModel, imageService: imageService)
    }
}


// MARK: - Lookup products
//
extension RefundedProductsDataSource {
    /// Resolves the image URL for a refunded item: the variation image when the item is a variation,
    /// otherwise the product image.
    ///
    func imageURL(for item: AggregateOrderItem) -> URL? {
        if item.variationID != 0 {
            guard let imageURLString = lookUpProductVariation(productID: item.productID, variationID: item.variationID)?.image?.src,
                  let encodedImageURLString = imageURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return nil
            }
            return URL(string: encodedImageURLString)
        }
        return lookUpProduct(by: item.productID)?.imageURL
    }

    private func lookUpProduct(by productID: Int64) -> OrderDetailsProduct? {
        return products.first(where: { $0.productID == productID })
    }

    private func lookUpProductVariation(productID: Int64, variationID: Int64) -> ProductVariation? {
        return productVariations.first(where: { $0.productID == productID && $0.productVariationID == variationID })
    }
}


// MARK: - Sections
extension RefundedProductsDataSource {
    /// Setup: Sections
    ///
    func reloadSections() {
        let refundedProductsSection: Section? = {
            let rows: [Row] = Array(repeating: .orderItemRefunded, count: refundedProducts.count)

            return Section(title: SectionTitle.product, rightTitle: nil, rows: rows)
        }()

        sections = [refundedProductsSection].compactMap { $0 }
    }
}


// MARK: - Constants
//
extension RefundedProductsDataSource {
    /// Section Titles
    ///
    enum SectionTitle {
        static let product = NSLocalizedString("Refunded Products", comment: "Refunded Products section title")
    }

    /// Table Rows
    ///
    enum Row {
        /// Listed in the order they appear on screen
        case orderItemRefunded

        var reuseIdentifier: String {
            switch self {
            case .orderItemRefunded:
                return ProductDetailsTableViewCell.reuseIdentifier
            }
        }
    }

    /// Table Sections
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
}
