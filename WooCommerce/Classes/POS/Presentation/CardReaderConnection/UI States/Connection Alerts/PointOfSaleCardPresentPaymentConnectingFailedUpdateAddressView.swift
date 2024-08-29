import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressView: View {
    @StateObject var viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel
    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.contentButtonSpacing) {
            VStack(spacing: PointOfSaleReaderConnectionModalLayout.imageTextSpacing) {
                Image(decorative: viewModel.imageName)

                Text(viewModel.title)
                    .font(POSFontStyle.posTitleEmphasized)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }

            if let primaryButtonViewModel = viewModel.primaryButtonViewModel {
                Button(primaryButtonViewModel.title,
                       action: primaryButtonViewModel.actionHandler)
                .buttonStyle(POSPrimaryButtonStyle())
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
