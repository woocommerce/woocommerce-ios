import SwiftUI

struct PointOfSaleCardPresentPaymentValidatingOrderMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentValidatingOrderMessageViewModel

    var body: some View {
        POSCardPresentPaymentMessageView(viewModel: .init(showProgress: true,
                                                          title: viewModel.title,
                                                          message: viewModel.message))
    }
}

#Preview {
    PointOfSaleCardPresentPaymentValidatingOrderMessageView(
        viewModel: PointOfSaleCardPresentPaymentValidatingOrderMessageViewModel())
}
