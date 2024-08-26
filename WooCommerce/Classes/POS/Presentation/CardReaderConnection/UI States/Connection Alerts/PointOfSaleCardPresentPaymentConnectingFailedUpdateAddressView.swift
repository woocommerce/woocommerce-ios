import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressView: View {
    @StateObject var viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel
    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .font(POSFontStyle.posBodyRegular)
                .accessibilityAddTraits(.isHeader)

            Image(decorative: viewModel.imageName)

            VStack(spacing: PointOfSaleReaderConnectionModalLayout.buttonSpacing) {
                if let primaryButtonViewModel = viewModel.primaryButtonViewModel {
                    Button(primaryButtonViewModel.title,
                           action: primaryButtonViewModel.actionHandler)
                    .buttonStyle(PrimaryButtonStyle())
                }

                Button(viewModel.cancelButtonViewModel.title,
                       action: viewModel.cancelButtonViewModel.actionHandler)
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
        .sheet(isPresented: $viewModel.shouldShowSettingsWebView) {
            WCSettingsWebView(adminUrl: viewModel.settingsAdminUrl,
                              completion: viewModel.settingsWebViewWasDismissed)
        }
    }
}

#Preview {
    PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressView(
        viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
            settingsAdminUrl: URL(string: "http://example.com")!,
            showsInAuthenticatedWebView: true,
            retrySearchAction: {},
            cancelSearchAction: {}))
}
