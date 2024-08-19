import SwiftUI

struct PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryView: View {
    private let viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryAlertViewModel

    init(viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .accessibilityAddTraits(.isHeader)

            viewModel.image

            Text(viewModel.batteryLevelInfo)

            Button(viewModel.cancelButtonViewModel.title,
                   action: viewModel.cancelButtonViewModel.actionHandler)
            .buttonStyle(SecondaryButtonStyle())
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryView(viewModel: .init(batteryLevel: nil, cancelUpdateAction: {}))
}
