import Foundation
import WooFoundation

class PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel: Hashable {
    let title = Localization.title
    let imageName = PointOfSaleAssets.readerConnectionSuccess.imageName
    let buttonViewModel: CardPresentPaymentsModalButtonViewModel
    private let scheduler: Scheduler
    private let autoDismissAction: Cancellable

    init(doneAction: @escaping () -> Void,
         scheduler: Scheduler = DefaultScheduler()) {

        self.scheduler = scheduler
        let autoDismissAction = scheduler.schedule(after: 3.0, action: doneAction)
        self.autoDismissAction = autoDismissAction

        self.buttonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.done,
            actionHandler: {
                autoDismissAction.cancel()
                doneAction()
            })
    }

    deinit {
        autoDismissAction.cancel()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(imageName)
        hasher.combine(buttonViewModel)
    }

    static func == (lhs: PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel, rhs: PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel) -> Bool {
        return lhs.title == rhs.title &&
               lhs.imageName == rhs.imageName &&
               lhs.buttonViewModel == rhs.buttonViewModel
    }
}

private extension PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectionSuccess.title",
            value: "Reader connected",
            comment: "Title of the alert presented when the user successfully connects a Bluetooth card reader"
        )

        static let done = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectionSuccess.done.button.title",
            value: "Done",
            comment: "Button to dismiss the alert presented when successfully connected to a reader"
        )
    }
}
