import SwiftUI

struct CardPresentPaymentConnectingFailedUpdateAddressView: View {
    @StateObject var viewModel: CardPresentPaymentConnectingFailedUpdateAddressAlertViewModel
    var body: some View {
        VStack {
            Text(viewModel.title)

            viewModel.image

            if let primaryButtonViewModel = viewModel.primaryButtonViewModel {
                Button(primaryButtonViewModel.title,
                       action: primaryButtonViewModel.actionHandler)
            }

            Button(viewModel.cancelButtonViewModel.title,
                   action: viewModel.cancelButtonViewModel.actionHandler)
            .buttonStyle(SecondaryButtonStyle())
        }
        .sheet(isPresented: $viewModel.shouldShowSettingsWebView) {
            WCSettingsWebView(adminUrl: viewModel.settingsAdminUrl,
                              completion: viewModel.settingsWebViewWasDismissed)
        }
    }
}

#Preview {
    CardPresentPaymentConnectingFailedUpdateAddressView(
        viewModel: CardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
            settingsAdminUrl: URL(string: "http://example.com")!,
            retrySearchAction: {},
            cancelSearchAction: {}))
}
