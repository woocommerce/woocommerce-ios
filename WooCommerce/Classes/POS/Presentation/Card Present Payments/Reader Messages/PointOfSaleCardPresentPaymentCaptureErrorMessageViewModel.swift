import Foundation
import enum Yosemite.CardReaderServiceError

final class PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel: ObservableObject {
    let title = Localization.title
    let message = Localization.message
    private(set) lazy var moreInfoButtonViewModel: CardPresentPaymentsModalButtonViewModel = CardPresentPaymentsModalButtonViewModel(
        title: Localization.moreInfo,
        actionHandler: { [weak self] in
            self?.showsInfoSheet = true
        })
    let cancelButtonViewModel: CardPresentPaymentsModalButtonViewModel

    @Published var showsInfoSheet: Bool = false

    init(cancelButtonAction: @escaping () -> Void) {
        self.cancelButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.cancel,
            actionHandler: cancelButtonAction)
    }

    func onAppear() {
        showsInfoSheet = true
    }
}

private extension PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.paymentCaptureError.title",
            value: "Payment status unknown",
            comment: "Error message. Presented to users after collecting a payment fails from payment capture error on the Point of Sale Checkout"
        )

        static let message = NSLocalizedString(
            "pointOfSale.cardPresent.paymentCaptureError.message",
            value: "We couldn't load complete order information to check the payment status. " +
            "Please check the latest order separately or retry.",
            comment: "Error message. Presented to users after collecting a payment fails from payment capture error on the Point of Sale Checkout"
        )

        static let moreInfo = NSLocalizedString(
            "pointOfSale.cardPresent.paymentCaptureError.moreInfo.button.title",
            value: "Learn more",
            comment: "Button to learn more about the payment capture error message. " +
            "Presented to users after collecting a payment fails from payment capture error on the Point of Sale Checkout"
        )

        static let cancel = NSLocalizedString(
            "pointOfSale.cardPresent.paymentCaptureError.cancel.button.title",
            value: "Retry payment",
            comment: "Button to dismiss payment capture error message. " +
            "Presented to users after collecting a payment fails from payment capture error on the Point of Sale Checkout"
        )
    }
}
