import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressView: View {
    @StateObject var viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel
    let animation: POSCardPresentPaymentAlertAnimation
    @Environment(\.posExternalViews) private var externalViews

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: PointOfSaleReaderConnectionModalLayout.imageTextSpacing) {
                Image(decorative: viewModel.imageName, bundle: .module)
                    .matchedGeometryEffect(id: animation.iconTransitionId, in: animation.namespace, properties: .position)

                Text(viewModel.title)
                    .font(POSFontStyle.posHeadingBold)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .matchedGeometryEffect(id: animation.titleTransitionId, in: animation.namespace, properties: .position)
            }

            if let primaryButtonViewModel = viewModel.primaryButtonViewModel {
                Spacer(minLength: PointOfSaleReaderConnectionModalLayout.contentButtonSpacing)

                Button(primaryButtonViewModel.title,
                       action: primaryButtonViewModel.actionHandler)
                .buttonStyle(POSFilledButtonStyle(size: .normal))
                .matchedGeometryEffect(id: animation.buttonsTransitionId, in: animation.namespace, properties: .position)
            }
        }
        .frame(maxHeight: .infinity)
        .posModalCloseButton(action: viewModel.cancelButtonViewModel.actionHandler,
                             accessibilityLabel: viewModel.cancelButtonViewModel.title)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
        .posSheet(isPresented: $viewModel.shouldShowSettingsWebView) {
            externalViews.createAuthenticatedWebView(url: viewModel.settingsAdminUrl,
                                                    title: Localization.settingsWebViewTitle,
                                                    completion: viewModel.settingsWebViewWasDismissed)
        }
    }
}

private extension PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressView {
    enum Localization {
        static let settingsWebViewTitle = NSLocalizedString(
            "pos.cardReader.updateAddress.webview.title",
            value: "WooCommerce Settings",
            comment: "Navigation title for the webview shown when the merchant needs to update their store address for card reader connection"
        )
    }
}

#Preview {
    @Previewable @Namespace var namespace
    return PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressView(
        viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
            settingsAdminUrl: URL(string: "http://example.com")!,
            showsInAuthenticatedWebView: true,
            retrySearchAction: {},
            cancelSearchAction: {}),
        animation: .init(namespace: namespace)
    )
}
