import SwiftUI

struct PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryView: View {
    private let viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Image(decorative: viewModel.imageName)

            Text(viewModel.title)
                .font(POSFontStyle.posTitleEmphasized)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text(viewModel.batteryLevelInfo)
                .font(POSFontStyle.posBodyRegular)
                .fixedSize(horizontal: false, vertical: true)

            Button(viewModel.cancelButtonViewModel.title,
                   action: viewModel.cancelButtonViewModel.actionHandler)
            .buttonStyle(POSSecondaryButtonStyle())
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryView(viewModel: .init(batteryLevel: nil, cancelUpdateAction: {}))
}
