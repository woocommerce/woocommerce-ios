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

    /// Designated Initializer
    ///
    init(order: Order, refund: Refund) {
        self.order = order
        self.refund = refund
    }

    /// Section Titles
    ///
    let productLeftTitle = NSLocalizedString("PRODUCT", comment: "Product section title")
    let productRightTitle = NSLocalizedString("QTY", comment: "Quantity abbreviation for section title")

    /// Products from a Refund
    ///
    var products: [Product] {
        return dataSource.products
    }

    /// The datasource that will be used to render the Refund Details screen
    ///
    private(set) lazy var dataSource: RefundDetailsDataSource = {
        return RefundDetailsDataSource(refund: self.refund, order: self.order)
    }()
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
                                                                   siteID: refund.siteID,
                                                                   currency: order.currency)
            let navController = WooNavigationController(rootViewController: loaderViewController)
            viewController.present(navController, animated: true, completion: nil)
        }
    }
}
