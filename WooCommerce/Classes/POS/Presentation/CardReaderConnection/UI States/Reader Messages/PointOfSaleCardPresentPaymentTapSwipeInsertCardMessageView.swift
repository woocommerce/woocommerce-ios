import SwiftUI

struct PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel

    var body: some View {
        let messageViewModel = POSCardPresentPaymentMessageViewModel(imageName: viewModel.imageName,
                                                                     title: viewModel.title,
                                                                     message: viewModel.message)
        POSCardPresentPaymentMessageView(viewModel: messageViewModel, style: .standard)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageView(
        viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel(
            inputMethods: [.tap, .insert]
        ))
}
