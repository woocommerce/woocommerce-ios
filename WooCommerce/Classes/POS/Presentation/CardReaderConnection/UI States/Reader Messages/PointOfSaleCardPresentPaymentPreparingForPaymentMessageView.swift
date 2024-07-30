import SwiftUI

struct PointOfSaleCardPresentPaymentPreparingForPaymentMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel

    var body: some View {
        PointOfSaleCardPresentPaymentValidatingOrderMessageView(title: viewModel.title, message: viewModel.message)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentPreparingForPaymentMessageView(
        viewModel: PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel())
}
