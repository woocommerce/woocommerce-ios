import SwiftUI

struct PointOfSaleCardPresentPaymentReaderUpdateFailedView: View {
    private let viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .font(POSFontStyle.posTitleEmphasized)
                .accessibilityAddTraits(.isHeader)

            Image(decorative: viewModel.imageName)

            Button(viewModel.retryButtonViewModel.title,
                   action: viewModel.retryButtonViewModel.actionHandler)
            .buttonStyle(PrimaryButtonStyle())
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
