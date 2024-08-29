import SwiftUI

struct PointOfSaleCardPresentPaymentBluetoothRequiredAlertView: View {
    private let viewModel: PointOfSaleCardPresentPaymentBluetoothRequiredAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentBluetoothRequiredAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .font(POSFontStyle.posTitleEmphasized)
                .accessibilityAddTraits(.isHeader)

            Image(decorative: viewModel.imageName)

            Text(viewModel.errorDetails)
                .font(POSFontStyle.posBodyRegular)

            Button(viewModel.openSettingsButtonViewModel.title,
                   action: viewModel.openSettingsButtonViewModel.actionHandler)
            .buttonStyle(PrimaryButtonStyle())
        }
        .posModalCloseButton(action: viewModel.dismissButtonViewModel.actionHandler,
                             accessibilityLabel: viewModel.dismissButtonViewModel.title)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentBluetoothRequiredAlertView(viewModel: .init(error: NSError(domain: "", code: 1),
                                                                             endSearch: {}))
}
