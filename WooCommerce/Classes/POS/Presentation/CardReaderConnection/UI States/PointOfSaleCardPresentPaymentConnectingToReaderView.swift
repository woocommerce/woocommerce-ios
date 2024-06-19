import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingToReaderView: View {
    private let viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text(viewModel.title)

            viewModel.image

            Text(viewModel.instruction)
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentConnectingToReaderView(viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel())
}
