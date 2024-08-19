import SwiftUI

struct PointOfSaleCardPresentPaymentFoundReaderView: View {
    let viewModel: PointOfSaleCardPresentPaymentFoundReaderAlertViewModel

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .accessibilityAddTraits(.isHeader)

            Image(decorative: viewModel.imageName)

            VStack(spacing: PointOfSaleReaderConnectionModalLayout.buttonSpacing) {
                Button(viewModel.connectButton.title,
                       action: viewModel.connectButton.actionHandler)
                .buttonStyle(PrimaryButtonStyle())

                Button(viewModel.continueSearchButton.title,
                       action: viewModel.continueSearchButton.actionHandler)
                .buttonStyle(SecondaryButtonStyle())

                Button(viewModel.cancelSearchButton.title,
                       action: viewModel.cancelSearchButton.actionHandler)
            }
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PointOfSaleCardPresentPaymentFoundReaderView(viewModel: PointOfSaleCardPresentPaymentFoundReaderAlertViewModel(
        readerName: "READER NAME",
        connectAction: {},
        continueSearchAction: {},
        endSearchAction: {}))
}
