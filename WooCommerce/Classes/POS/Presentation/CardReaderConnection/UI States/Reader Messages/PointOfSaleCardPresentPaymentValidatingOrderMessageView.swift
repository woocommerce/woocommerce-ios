import SwiftUI

struct PointOfSaleCardPresentPaymentValidatingOrderMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentValidatingOrderMessageViewModel

    var body: some View {
        let messageViewModel = POSCardPresentPaymentMessageViewModel(showProgress: true,
                                                                     title: viewModel.title,
                                                                     message: viewModel.message)
        POSCardPresentPaymentMessageView(viewModel: messageViewModel, style: .dimmed)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentValidatingOrderMessageView(
        viewModel: PointOfSaleCardPresentPaymentValidatingOrderMessageViewModel())
}
