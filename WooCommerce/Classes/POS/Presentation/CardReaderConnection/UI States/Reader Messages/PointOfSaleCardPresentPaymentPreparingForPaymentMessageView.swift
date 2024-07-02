import SwiftUI

struct PointOfSaleCardPresentPaymentPreparingForPaymentMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel

    var body: some View {
        POSCardPresentPaymentMessageView(viewModel: .init(showProgress: true,
                                                          title: viewModel.title,
                                                          message: viewModel.message))
    }
}

#Preview {
    PointOfSaleCardPresentPaymentPreparingForPaymentMessageView(
        viewModel: PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel())
}
