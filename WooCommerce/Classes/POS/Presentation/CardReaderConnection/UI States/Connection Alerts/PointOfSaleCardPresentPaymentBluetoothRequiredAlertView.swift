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

            VStack(spacing: PointOfSaleReaderConnectionModalLayout.buttonSpacing) {
                Button(viewModel.openSettingsButtonViewModel.title,
                       action: viewModel.openSettingsButtonViewModel.actionHandler)
                .buttonStyle(PrimaryButtonStyle())

                Button(viewModel.dismissButtonViewModel.title,
                       action: viewModel.dismissButtonViewModel.actionHandler)
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentBluetoothRequiredAlertView(viewModel: .init(error: NSError(domain: "", code: 1),
                                                                             endSearch: {}))
}
