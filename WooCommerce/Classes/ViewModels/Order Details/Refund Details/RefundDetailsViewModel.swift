import Foundation
import UIKit
import Yosemite


/// All things view-related for Refunds.
///
final class RefundDetailsViewModel {
    /// Refund
    ///
    private(set) var refund: Refund

    /// Order
    ///
    private(set) var order: Order

    /// Currency Formatter
    ///
    let currencyFormatter = CurrencyFormatter()

    /// Designated Initializer
    ///
    init(order: Order, refund: Refund) {
        self.order = order
        self.refund = refund
    }

    /// Products from a Refund
    ///
    var products: [Product] {
        return dataSource.products
    }

    /// Subtotal from all refunded products
    ///
    var itemSubtotal: String {
        let subtotal = calculateItemSubtotal()
        let formattedSubtotal = currencyFormatter.formatAmount(subtotal, with: order.currency) ?? String()

        return formattedSubtotal
    }

    /// Tax subtotal from all refunded products
    ///
    var taxSubtotal: String {
        let subtotalTax = calculateSubtotalTax()
        let formattedSubtotalTax = currencyFormatter.formatAmount(subtotalTax, with: order.currency) ?? String()

        return formattedSubtotalTax
    }

    /// Products Refund
    ///
    var productsRefund: String {
        let subtotal = calculateItemSubtotal()
        let subtotalTax = calculateSubtotalTax()
        let productsRefundTotal = subtotal.adding(subtotalTax)
        let formattedProductsRefund = currencyFormatter.formatAmount(productsRefundTotal, with: order.currency)

        return formattedProductsRefund ?? String()
    }

    /// The datasource that will be used to render the Refund Details screen
    ///
    private(set) lazy var dataSource: RefundDetailsDataSource = {
        return RefundDetailsDataSource(refund: self.refund, order: self.order)
    }()
}


// MARK: - Private methods
//
private extension RefundDetailsViewModel {
    /// Calculate the subtotal for each returned item
    ///
    func calculateItemSubtotal() -> NSDecimalNumber {
        let itemSubtotals = refund.items.map { currencyFormatter.convertToDecimal(from: $0.subtotal) }

        var subtotal = NSDecimalNumber.zero
        for itemSubtotal in itemSubtotals {
            if let i = itemSubtotal {
                subtotal = subtotal.adding(i)
            }
        }

        if subtotal.isNegative() {
            subtotal = subtotal.multiplying(by: -1)
        }

        return subtotal.abs()
    }

    /// Calculate the subtotal tax for each returned item
    ///
    func calculateSubtotalTax() -> NSDecimalNumber {
        let itemSubtotalTaxes = refund.items.map { currencyFormatter.convertToDecimal(from: $0.subtotalTax) }

        var subtotalTax = NSDecimalNumber.zero
        for itemSubtotalTax in itemSubtotalTaxes {
            if let i = itemSubtotalTax {
                subtotalTax = subtotalTax.adding(i)
            }
        }

        return subtotalTax.abs()
    }
}


// MARK: - Configuring results controllers
//
extension RefundDetailsViewModel {
    func configureResultsControllers(onReload: @escaping () -> Void) {
        dataSource.configureResultsControllers(onReload: onReload)
    }
}


// MARK: - UITableViewDelegate methods
//
extension RefundDetailsViewModel {
    /// Reload the section data
    ///
    func reloadSections() {
        dataSource.reloadSections()
    }

    /// Handle taps on cells
    ///
    func tableView(_ tableView: UITableView,
                   in viewController: UIViewController,
                   didSelectRowAt indexPath: IndexPath) {
        switch dataSource.sections[indexPath.section].rows[indexPath.row] {

        case .orderItem:
            let item = refund.items[indexPath.row]
            let productID = item.variationID == 0 ? item.productID : item.variationID
            let loaderViewController = ProductLoaderViewController(productID: productID,
                                                                   siteID: refund.siteID)
            let navController = WooNavigationController(rootViewController: loaderViewController)
            viewController.present(navController, animated: true, completion: nil)

        default:
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
