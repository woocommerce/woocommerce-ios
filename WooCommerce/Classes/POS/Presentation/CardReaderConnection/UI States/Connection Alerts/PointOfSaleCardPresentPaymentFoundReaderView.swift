import SwiftUI

struct PointOfSaleCardPresentPaymentFoundReaderView: View {
    let viewModel: PointOfSaleCardPresentPaymentFoundReaderAlertViewModel

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
                Image(decorative: viewModel.imageName)

                Text(viewModel.title)
                    .font(POSFontStyle.posTitleEmphasized)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text(viewModel.description)
                    .font(POSFontStyle.posBodyRegular)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .scrollVerticallyIfNeeded()

            VStack(spacing: PointOfSaleReaderConnectionModalLayout.buttonSpacing) {
                Button(viewModel.connectButton.title,
                       action: viewModel.connectButton.actionHandler)
                .buttonStyle(POSPrimaryButtonStyle())

                Button(viewModel.continueSearchButton.title,
                       action: viewModel.continueSearchButton.actionHandler)
                .buttonStyle(POSSecondaryButtonStyle())
            }
        }
        .posModalCloseButton(action: viewModel.cancelSearchButton.actionHandler,
                             accessibilityLabel: viewModel.cancelSearchButton.title)
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
