import SwiftUI

struct PointOfSaleCardPresentPaymentInLineMessage: View {
    private let messageType: PointOfSaleCardPresentPaymentMessageType

    init(messageType: PointOfSaleCardPresentPaymentMessageType) {
        self.messageType = messageType
    }

    var body: some View {

        // TODO: replace temporary inline message UI based on design
        switch messageType {
        case .validatingOrder(let viewModel):
            PointOfSaleCardPresentPaymentValidatingOrderMessageView(viewModel: viewModel)
        case .preparingForPayment(let viewModel):
            PointOfSaleCardPresentPaymentPreparingForPaymentMessageView(viewModel: viewModel)
        case .tapSwipeOrInsertCard(let viewModel):
            PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageView(viewModel: viewModel)
        case .processing(let viewModel):
            POSCardPresentPaymentMessageView(viewModel: POSCardPresentPaymentMessageViewModel(imageName: viewModel.imageName, title: viewModel.title))
        case .displayReaderMessage(let viewModel):
            PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView(viewModel: viewModel)
        case .paymentSuccess(let viewModel):
            POSCardPresentPaymentMessageView(viewModel: POSCardPresentPaymentMessageViewModel(imageName: viewModel.imageName, title: viewModel.title))
        case .paymentError(let viewModel):
            PointOfSaleCardPresentPaymentErrorMessageView(viewModel: viewModel)
        case .paymentErrorNonRetryable(let viewModel):
            PointOfSaleCardPresentPaymentNonRetryableErrorMessageView(viewModel: viewModel)
        case .paymentCaptureError(let viewModel):
            PointOfSaleCardPresentPaymentCaptureErrorMessageView(viewModel: viewModel)
        case .cancelledOnReader(let viewModel):
            POSCardPresentPaymentMessageView(viewModel: POSCardPresentPaymentMessageViewModel(title: viewModel.title))
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentInLineMessage(messageType: .processing(
        viewModel: PointOfSaleCardPresentPaymentProcessingMessageViewModel()))
}
