import SwiftUI

struct PointOfSaleCardPresentPaymentBluetoothRequiredAlertView: View {
    private let viewModel: PointOfSaleCardPresentPaymentBluetoothRequiredAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentBluetoothRequiredAlertViewModel) {
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

                Text(viewModel.errorDetails)
                    .font(POSFontStyle.posBodyRegular)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .scrollVerticallyIfNeeded()

            Button(viewModel.openSettingsButtonViewModel.title,
                   action: viewModel.openSettingsButtonViewModel.actionHandler)
            .buttonStyle(POSPrimaryButtonStyle())
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
