import Foundation
import Yosemite

struct PointOfSaleCardPresentCreatingReceiptMessageViewModel: Equatable {
    let title: String = "Receipt"
    let buttonTitle: String = "Email receipt"
    let message: String = "maybe some more receipt lorem ipsum"
    let order: Order

    func send(toAddress: String, onCompletion: @escaping () -> Void) {
        let action = ReceiptAction.sendReceipt(order: order, email: toAddress, onCompletion: { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // TODO:
                        // Dismissal on completion, at the moment dismisses the whole POS view
                        onCompletion()
                    }
                case let .failure(error):
                    DDLogError("Sending email receipt failed: \(error.localizedDescription)")
                    // TODO:
                    // Handle error when sending email
                }
            }
        })
        ServiceLocator.stores.dispatch(action)
    }
}

enum PointOfSaleCardPresentPaymentMessageType: Equatable {
    case validatingOrder(viewModel: PointOfSaleCardPresentPaymentValidatingOrderMessageViewModel)
    case validatingOrderError(viewModel: PointOfSaleCardPresentPaymentValidatingOrderErrorMessageViewModel)
    case preparingForPayment(viewModel: PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel)
    case tapSwipeOrInsertCard(viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel)
    case processing(viewModel: PointOfSaleCardPresentPaymentProcessingMessageViewModel)
    case displayReaderMessage(viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel)
    case paymentSuccess(viewModel: PointOfSaleCardPresentPaymentSuccessMessageViewModel)
    case creatingReceipt(viewModel: PointOfSaleCardPresentCreatingReceiptMessageViewModel)
    case paymentError(viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel)
    case paymentErrorNonRetryable(viewModel: PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel)
    case paymentCaptureError(viewModel: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel)
    case paymentIntentCreationError(viewModel: PointOfSaleCardPresentPaymentIntentCreationErrorMessageViewModel)
    case cancelledOnReader(viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel)
}
