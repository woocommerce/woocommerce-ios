import Foundation
import UIKit
import Yosemite


/// All things view-related for Refunds.
///
final class RefundDetailsViewModel {
    /// Refund
    ///
    private(set) var refund: Refund

    /// Designated Initializer
    ///
    init(refund: Refund) {
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
        return RefundDetailsDataSource(refund: self.refund)
    }()
}
