import Foundation
import Yosemite

/// Controls navigation for the issue refund feedback flow. Meant to be presented modally.
///
final class IssueRefundCoordinatingController: WooNavigationController {

    /// Order to be refunded.
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

        // Select Quantity Action
        issueRefundViewController.onSelectQuantityAction = { [weak self] command in
            self?.navigateToItemQuantitySelection(using: command) { selectedQuantity in
                issueRefundViewController.updateRefundQuantity(quantity: selectedQuantity, forItemAtIndex: command.itemIndex)
            }

        }

        // Next Action
        issueRefundViewController.onNextAction = { [weak self] viewModel in
            self?.navigateToRefundConfirmation(with: viewModel)
        }

        setViewControllers([issueRefundViewController], animated: false)
    }

    /// Navigates to `ListSelectorViewController` with the provided command.
    /// `onCompletion` will be executed with the "selected quantity" value.
    ///
    func navigateToItemQuantitySelection(using command: RefundItemQuantityListSelectorCommand, onCompletion: @escaping (Int) -> Void) {
        let selectorViewController = ListSelectorViewController(command: command, tableViewStyle: .plain) { selectedQuantity in
            guard let selectedQuantity = selectedQuantity else {
                return
            }
            onCompletion(selectedQuantity)
        }
        show(selectorViewController, sender: nil)
    }

    /// Navigates to `RefundConfirmationViewController` with the provided view model.
    ///
    func navigateToRefundConfirmation(with viewModel: RefundConfirmationViewModel) {
        let refundConfirmationViewController = RefundConfirmationViewController(viewModel: viewModel)
        show(refundConfirmationViewController, sender: nil)
    }
}
