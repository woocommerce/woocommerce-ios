import SwiftUI

struct PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView: View {
    let viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel

    var body: some View {
        POSCardPresentPaymentMessageView(viewModel: .init(message: viewModel.message))
    }
}

#Preview {
    PointOfSaleCardPresentPaymentDisplayReaderMessageMessageView(
        viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel(
            message: "Please remove card"))
}
