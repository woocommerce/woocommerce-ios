import SwiftUI

struct PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableView: View {
    private let viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.contentButtonSpacing) {
            VStack(spacing: PointOfSaleReaderConnectionModalLayout.imageTextSpacing) {
                Image(decorative: viewModel.imageName)

                Text(viewModel.title)
                    .font(POSFontStyle.posTitleEmphasized)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }

            Button(viewModel.cancelButtonViewModel.title,
                   action: viewModel.cancelButtonViewModel.actionHandler)
            .buttonStyle(POSSecondaryButtonStyle())
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableView(viewModel: .init(cancelUpdateAction: {}))
}
