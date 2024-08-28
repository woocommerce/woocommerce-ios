import SwiftUI

struct PointOfSaleCardPresentPaymentReaderUpdateFailedView: View {
    private let viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
                Image(decorative: viewModel.imageName)

                Text(viewModel.title)
                    .font(POSFontStyle.posTitleEmphasized)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            .frame(maxWidth: .infinity)
            .scrollVerticallyIfNeeded()

            Button(viewModel.retryButtonViewModel.title,
                   action: viewModel.retryButtonViewModel.actionHandler)
            .buttonStyle(POSPrimaryButtonStyle())
        }
        .posModalCloseButton(action: viewModel.cancelButtonViewModel.actionHandler,
                             accessibilityLabel: viewModel.cancelButtonViewModel.title)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentReaderUpdateFailedView(viewModel: .init(retryAction: {}, cancelUpdateAction: {}))
}
