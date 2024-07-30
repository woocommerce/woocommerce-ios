import SwiftUI

struct PointOfSaleCardPresentPaymentPreparingForPaymentMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel

    var body: some View {
        let messageViewModel = POSCardPresentPaymentMessageViewModel(showProgress: true,
                                                                     title: viewModel.title,
                                                                     message: viewModel.message)
        POSCardPresentPaymentMessageView(viewModel: messageViewModel, style: .dimmed)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentPreparingForPaymentMessageView(
        viewModel: PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel())
}
