import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingToReaderView: View {
    private let viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .accessibilityAddTraits(.isHeader)

            Image(decorative: viewModel.imageName)

            Text(viewModel.instruction)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentConnectingToReaderView(viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel())
}
