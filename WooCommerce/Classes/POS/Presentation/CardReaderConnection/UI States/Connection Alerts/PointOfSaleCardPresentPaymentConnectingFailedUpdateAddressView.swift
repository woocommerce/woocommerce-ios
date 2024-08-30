import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressView: View {
    @StateObject var viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel
    let animation: POSCardPresentPaymentAlertAnimation

    var body: some View {
        VStack(spacing: PointOfSaleReaderConnectionModalLayout.contentButtonSpacing) {
            VStack(spacing: PointOfSaleReaderConnectionModalLayout.imageTextSpacing) {
                Image(decorative: viewModel.imageName)
                    .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.title)
                    .font(POSFontStyle.posTitleEmphasized)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)
            }

            if let primaryButtonViewModel = viewModel.primaryButtonViewModel {
                Button(primaryButtonViewModel.title,
                       action: primaryButtonViewModel.actionHandler)
                .buttonStyle(POSPrimaryButtonStyle())
                .matchedGeometryEffect(id: animation.buttonsTransitionId, in: animation.namespace, properties: .position)
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
    @Namespace var namespace
    return PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressView(
        viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
            settingsAdminUrl: URL(string: "http://example.com")!,
            showsInAuthenticatedWebView: true,
            retrySearchAction: {},
            cancelSearchAction: {}),
        animation: .init(namespace: namespace)
    )
}
