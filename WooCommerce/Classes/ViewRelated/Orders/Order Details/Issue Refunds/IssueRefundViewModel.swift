import Foundation
import Yosemite

/// ViewModel for presenting the issue refund screen to the user.
///
final class IssueRefundViewModel {

    /// Order to be refunded
    ///
    private let order: Order

    /// Title for the navigation bar
    /// This is temporary data, will be removed after implementing https://github.com/woocommerce/woocommerce-ios/issues/2842
    ///
    let title: String = "$0.00"

    /// String indicating how many items the user has selected to refund
    /// This is temporary data, will be removed after implementing https://github.com/woocommerce/woocommerce-ios/issues/2842
    ///
    let selectedItemsTitle: String = "0 items selected"

    /// The sections and rows to display in the `UITableView`.
    ///
    private(set) var sections: [Section] = []

    /// Products related to this order. Needed to build `RefundItemViewModel` rows
    ///
    private lazy var products: [Product] = {
        let resultsController = createProductsResultsController()
        try? resultsController.performFetch()
        return resultsController.fetchedObjects
    }()

    init(order: Order, currencySettings: CurrencySettings) {
        self.order = order

        // This is temporary data, will be removed after implementing https://github.com/woocommerce/woocommerce-ios/issues/2842
        sections = [
            createItemsToRefundSection(currencySettings: currencySettings),
            Section(rows: [
                ShippingSwitchViewModel(title: "Refund Shipping", isOn: true),
                RefundShippingDetailsViewModel(shippingLine: order.shippingLines[0], currency: order.currency, currencySettings: currencySettings)
            ])
        ]
    }
}

// MARK: Results Controller
private extension IssueRefundViewModel {

    /// Results controller that fetches the products related to this order
    ///
    func createProductsResultsController() -> ResultsController<StorageProduct> {
        let itemsIDs = order.items.map { $0.productID }
        let predicate = NSPredicate(format: "siteID == %lld AND productID IN %@", order.siteID, itemsIDs)
        return ResultsController<StorageProduct>(storageManager: ServiceLocator.storageManager, matching: predicate, sortedBy: [])
    }
}

// MARK: Sections and Rows

/// Protocol that any `Section` item  should conform to.
///
protocol IssueRefundRow {}

extension IssueRefundViewModel {

    struct Section {
        let rows: [IssueRefundRow]
    }

    /// ViewModel that represents the shipping switch row.
    struct ShippingSwitchViewModel: IssueRefundRow {
        let title: String
        let isOn: Bool
    }

    /// Returns a section with the order items that can be refunded
    ///
    private func createItemsToRefundSection(currencySettings: CurrencySettings) -> Section {
        let itemsRows = order.items.map { item -> RefundItemViewModel in
            let product = products.filter { $0.productID == item.productID }.first
            return RefundItemViewModel(item: item, product: product, currency: order.currency, currencySettings: currencySettings)
        }

        // This is temporary data, will be removed after implementing https://github.com/woocommerce/woocommerce-ios/issues/2842
        let summaryRow = RefundProductsTotalViewModel(productsTax: "$0.00", productsSubtotal: "$0.00", productsTotal: "$0.00")

        return Section(rows: itemsRows + [summaryRow])
    }
}

extension RefundItemViewModel: IssueRefundRow {}

extension RefundProductsTotalViewModel: IssueRefundRow {}

extension RefundShippingDetailsViewModel: IssueRefundRow {}
