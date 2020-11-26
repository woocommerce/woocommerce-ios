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
        issueRefundViewController.onSelectQuantityAction = { [weak self] command in
            self?.navigateToItemQuantitySelection(using: command)

        }
        issueRefundViewController.onNextAction = { [weak self] viewModel in
            self?.navigateToRefundConfirmation(with: viewModel)
        }

        setViewControllers([issueRefundViewController], animated: false)
    }

    /// Navigates to `ListSelectorViewController` with the provided command.
    ///
    func navigateToItemQuantitySelection(using command: RefundItemQuantityListSelectorCommand) {
        let selectorViewController = ListSelectorViewController(command: command, tableViewStyle: .plain) { [weak self] selectedQuantity in
            guard let selectedQuantity = selectedQuantity else {
                return
            }
            // TODO: Handle Selection
//            self?.viewModel.updateRefundQuantity(quantity: selectedQuantity, forItemAtIndex: indexPath.row)
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
