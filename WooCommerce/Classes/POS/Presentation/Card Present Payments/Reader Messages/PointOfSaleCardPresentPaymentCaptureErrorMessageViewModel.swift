import Foundation
import enum Yosemite.CardReaderServiceError

final class PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel: ObservableObject, Equatable {
    let id = UUID()
    let title = Localization.title
    let message = Localization.message
    let nextStep = Localization.nextStep
    let tryAgainButtonViewModel: CardPresentPaymentsModalButtonViewModel
    let newOrderButtonViewModel: CardPresentPaymentsModalButtonViewModel

    @Published var showsInfoSheet: Bool = false

    init(tryAgainButtonAction: @escaping () -> Void,
         newOrderButtonAction: @escaping () -> Void) {
        self.tryAgainButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.tryPaymentAgain,
            actionHandler: tryAgainButtonAction)
        self.newOrderButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.newOrder,
            actionHandler: newOrderButtonAction)
    }

    func onAppear() {
        showsInfoSheet = true
    }

    static func == (lhs: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel, rhs: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.message == rhs.message  &&
        lhs.nextStep == rhs.nextStep &&
        lhs.tryAgainButtonViewModel == rhs.tryAgainButtonViewModel &&
        lhs.newOrderButtonViewModel == rhs.newOrderButtonViewModel &&
        lhs.showsInfoSheet == rhs.showsInfoSheet
    }
}

private extension PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.paymentCaptureError.unable.to.confirm.title",
            value: "Payment error",
            comment: "Error message. Presented to users after collecting a payment fails from payment capture error " +
            "on the Point of Sale Checkout"
        )

        static let message = NSLocalizedString(
            "pointOfSale.cardPresent.paymentCaptureError.unable.to.confirm.message",
            value: "Due to a network error, we’re unable to confirm that the payment succeeded.",
            comment: "Error message. Presented to users after collecting a payment fails from payment capture error " +
            "on the Point of Sale Checkout"
        )

        static let nextStep = NSLocalizedString(
            "pointOfSale.cardPresent.paymentCaptureError.nextSteps",
            value: "Verify payment on a device with a working network connection. If unsuccessful, retry the payment. " +
            "If successful, start a new order.",
            comment: "Next steps hint for what to do after seeing a payment capture error message. Presented to users " +
            "after collecting a payment fails from payment capture error on the Point of Sale Checkout")

        static let tryPaymentAgain = NSLocalizedString(
            "pointOfSale.cardPresent.paymentCaptureError.tryPaymentAgain.button.title",
            value: "Try payment again",
            comment: "Button to dismiss payment capture error message. " +
            "Presented to users after collecting a payment fails from payment capture error on the Point of Sale Checkout"
        )

        static let newOrder = NSLocalizedString(
            "pointOfSale.cardPresent.paymentCaptureError.newOrder.button.title",
            value: "New order",
            comment: "Button to dismiss payment capture error message. " +
            "Presented to users after collecting a payment fails from payment capture error on the Point of Sale Checkout"
        )
    }
}
