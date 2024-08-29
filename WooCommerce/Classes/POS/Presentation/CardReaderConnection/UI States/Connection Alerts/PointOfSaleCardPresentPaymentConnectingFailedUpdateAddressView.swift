import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressView: View {
    @StateObject var viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel
    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.verticalSpacing) {
            Text(viewModel.title)
                .font(POSFontStyle.posTitleEmphasized)
                .accessibilityAddTraits(.isHeader)

            Image(decorative: viewModel.imageName)

            if let primaryButtonViewModel = viewModel.primaryButtonViewModel {
                Button(primaryButtonViewModel.title,
                       action: primaryButtonViewModel.actionHandler)
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .posModalCloseButton(action: viewModel.cancelButtonViewModel.actionHandler,
                             accessibilityLabel: viewModel.cancelButtonViewModel.title)
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
