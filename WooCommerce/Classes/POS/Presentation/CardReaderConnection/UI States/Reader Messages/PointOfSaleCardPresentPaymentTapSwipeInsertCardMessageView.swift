import SwiftUI

struct PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel

    var body: some View {
        POSCardPresentPaymentMessageView(viewModel: .init(imageName: "pos_ready_for_payment",
                                                          title: viewModel.title,
                                                          message: viewModel.message,
                                                          buttons: [viewModel.cancelButtonViewModel]))
    }
}

#Preview {
    PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageView(
        viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel(
            inputMethods: [.tap, .insert],
            cancelAction: {}
        ))
}
