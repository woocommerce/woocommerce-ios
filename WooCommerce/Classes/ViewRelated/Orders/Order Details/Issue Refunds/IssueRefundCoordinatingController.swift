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

    /// Used to display a success notice after the flow has finished.
    ///
    private let systemNoticePresenter: NoticePresenter

    init(order: Order, refunds: [Refund], systemNoticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {
        self.order = order
        self.refunds = refunds
        self.systemNoticePresenter = systemNoticePresenter
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

        // Select quantity action
        issueRefundViewController.onSelectQuantityAction = { [weak self] command in
            self?.navigateToItemQuantitySelection(using: command) { selectedQuantity in
                issueRefundViewController.updateRefundQuantity(quantity: selectedQuantity, forItemAtIndex: command.itemIndex)
            }

        }

        // Next action
        issueRefundViewController.onNextAction = { [weak self] viewModel in
            self?.navigateToRefundConfirmation(with: viewModel)
        }

        setViewControllers([issueRefundViewController], animated: false)
    }

    /// Navigates to `ListSelectorViewController` with the provided command.
    /// - Parameter onCompletion: Closure to be invoked  with the "selected quantity" value.
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

        // Confirmation & submission action
        refundConfirmationViewController.onRefundButtonAction = { [weak self] in
            self?.presetRefundConfirmationAlert(amount: viewModel.refundAmount) { didConfirm in
                if didConfirm {
                    refundConfirmationViewController.submitRefund()
                }
            }
        }

        // Issuing refund action
        refundConfirmationViewController.onRefundCreationAction = { [weak self] in
            self?.presentProgressViewController()
        }

        // Issued refund action
        refundConfirmationViewController.onRefundCompletion = { [weak self] error in
            if error == nil {
                self?.dismissIssueRefundFlow()
            } else {
                self?.dismissProgressViewController()
            }
        }

        show(refundConfirmationViewController, sender: nil)
    }

    /// Displays a confirmation alert before issuing a refund.
    /// - Parameter onCompletion: Closure to be invoked with the user selection. `True` continue with the refund. `False` don't issue the refund.
    ///
    func presetRefundConfirmationAlert(amount: String, onCompletion: @escaping (Bool) -> Void) {
        let actionSheet = UIAlertController(title: Localization.confirmationTitle(amount: amount),
                                            message: Localization.confirmationBody,
                                            preferredStyle: .alert)
        actionSheet.view.tintColor = .text
        actionSheet.addCancelActionWithTitle(Localization.cancel) { _ in
            onCompletion(false)
        }

        actionSheet.addDefaultActionWithTitle(Localization.refund) { _ in
            onCompletion(true)
        }

        present(actionSheet, animated: true)
    }

    /// Shows a progress view while the refund is being created.
    ///
    func presentProgressViewController() {
        let viewProperties = InProgressViewProperties(title: Localization.issuingRefund, message: "")
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)

        // Before iOS 13, a modal with transparent background requires certain
        // `modalPresentationStyle` to prevent the view from turning dark after being presented.
        if #available(iOS 13.0, *) {} else {
            inProgressViewController.modalPresentationStyle = .overCurrentContext
        }

        present(inProgressViewController, animated: true)
    }

    /// Dismisses the progress view. Assumes it is the latest presented view controller.
    ///
    func dismissProgressViewController() {
        dismiss(animated: true)
    }

    /// Dismisses the whole `IssueRefund` flow and presents a success notice.
    ///
    func dismissIssueRefundFlow() {
        presentingViewController?.dismiss(animated: true) { [weak self] in
            self?.systemNoticePresenter.enqueue(notice: .init(title: Localization.refundSuccess))
        }
    }
}

// MARK: Constants
private extension IssueRefundCoordinatingController {
    enum Localization {
        static let refund = NSLocalizedString("Refund", comment: "The title of the button to confirm the refund.")
        static let cancel = NSLocalizedString("Cancel", comment: "The title of the button to cancel issuing a refund.")
        static let issuingRefund = NSLocalizedString("Issuing Refund...", comment: "Text of the screen that is displayed while the refund is being created.")
        static let refundSuccess = NSLocalizedString("🎉 Products successfully refunded",
                                                     comment: "Text of the notice that is displayed after the refund is created.")
        static let confirmationBody = NSLocalizedString("Are you sure you want to issue a refund? This can't be undone.",
                                                        comment: "The text on the confirmation alert before issuing a refund.")
        static func confirmationTitle(amount: String) -> String {
            "\(refund) \(amount)"
        }
    }
}
