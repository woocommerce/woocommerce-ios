import SwiftUI

struct PointOfSaleCardPresentPaymentPreparingForPaymentMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel

    var body: some View {
        POSCardPresentPaymentMessageView(viewModel: .init(showProgress: true,
                                                          message: viewModel.message,
                                                          buttons: [viewModel.cancelButtonViewModel]))
    }
}

#Preview {
    PointOfSaleCardPresentPaymentPreparingForPaymentMessageView(
        viewModel: PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel(cancelAction: {}))
}
