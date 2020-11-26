import Foundation
import Yosemite

/// Controls navigation for the issue refund feedback flow. Meant to be presented modally.
///
final class IssueRefundCoordinatingController: WooNavigationController {

    /// Order to be refunded
    ///
    private let order: Order

    /// Previous refunds made to order.
    ///
    private let refunds: [Refund]

    init(order: Order, refunds: [Refund]) {
        self.order = order
        self.refunds = refunds
        super.init(nibName: nil, bundle: nil)
        startRefundNavigation()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Navigation
private extension IssueRefundCoordinatingController {

    /// Starts navigation with `IssueRefundViewController` as the root view controller.
    ///
    func startRefundNavigation() {
        let issueRefundViewController = IssueRefundViewController(order: order, refunds: refunds)
        setViewControllers([issueRefundViewController], animated: false)
    }
}
