import Foundation
import Yosemite


// MARK: - Refunded Products View Model
//
struct RefundedProductsViewModel {
    /// Order we're observing.
    ///
    private let order: Order

    /// Array of full refunds.
    ///
    private(set) var refunds: [Refund]

    /// The datasource that will be used to render the Order Details screen
    ///
    private(set) lazy var dataSource: RefundedProductsDataSource = {
        return RefundedProductsDataSource(order: self.order, refunds: self.refunds)
    }()

    /// Designated initializer.
    ///
    init(order: Order, refunds: [Refund]) {
        self.order = order
        self.refunds = refunds
    }
}
