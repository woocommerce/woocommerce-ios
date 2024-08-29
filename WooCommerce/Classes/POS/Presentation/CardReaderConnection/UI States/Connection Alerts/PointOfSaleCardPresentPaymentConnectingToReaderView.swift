import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingToReaderView: View {
    private let viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.imageTextSpacing) {
            Image(decorative: viewModel.imageName)

            VStack(spacing: PointOfSaleReaderConnectionModalLayout.textSpacing) {
                Text(viewModel.title)
                    .font(POSFontStyle.posTitleEmphasized)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text(viewModel.instruction)
                    .font(POSFontStyle.posBodyRegular)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentConnectingToReaderView(viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel())
}
