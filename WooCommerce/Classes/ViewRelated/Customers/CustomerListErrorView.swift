import SwiftUI

struct CustomerListErrorView: View {
    @Bindable var viewModel: CustomerListErrorViewModel

    @State private var isConfirmingAnalytics = false

    var body: some View {
        Group {
            switch viewModel.state {
            case .hidden:
                EmptyView()
            case .checking:
                ProgressView()
            case let .shown(message):
                errorContent(message: message)
            case .generic:
                errorContent(message: nil)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .listBackground))
        .notice($viewModel.notice)
        .alert(Localization.confirmationTitle, isPresented: $isConfirmingAnalytics) {
            Button(Localization.confirm) {
                Task { await viewModel.enableAnalytics() }
            }
            Button(Localization.cancel, role: .cancel) {}
        } message: {
            Text(Localization.confirmationMessage)
        }
    }

    @ViewBuilder
    private func errorContent(message: CustomerListErrorViewModel.Message?) -> some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Image(uiImage: .errorImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: Layout.imageWidth)
                        .fixedSize()
                        .accessibilityHidden(true)
                        .padding(.bottom, Layout.imageBottomSpacing)

                    Text(Localization.title)
                        .headlineStyle()

                    Text(message.map(Localization.message(for:)) ?? Localization.genericErrorMessage)
                        .bodyStyle()
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Layout.textSpacing)

                    if message == .disabled {
                        Button(Localization.enableAnalytics) {
                            isConfirmingAnalytics = true
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .frame(maxWidth: Layout.buttonWidth)
                        .padding(.top, Layout.buttonTopSpacing)

                        Button(Localization.retry) {
                            viewModel.retry()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .frame(maxWidth: Layout.buttonWidth)
                        .padding(.top, Layout.secondaryButtonSpacing)
                    } else {
                        Button(Localization.retry) {
                            viewModel.retry()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .frame(maxWidth: Layout.buttonWidth)
                        .padding(.top, Layout.buttonTopSpacing)
                    }
                }
                .multilineTextAlignment(.center)
                .padding(Layout.contentPadding)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

private extension CustomerListErrorView {
    enum Layout {
        static let imageBottomSpacing: CGFloat = 48
        static let textSpacing: CGFloat = 4
        static let buttonTopSpacing: CGFloat = 24
        static let secondaryButtonSpacing: CGFloat = 8
        static let contentPadding: CGFloat = 24
        static let imageWidth: CGFloat = 168
        static let buttonWidth: CGFloat = 228
    }

    enum Localization {
        static let title = NSLocalizedString(
            "customers.error.title",
            value: "Customers can't be loaded",
            comment: "Title for the customer loading error state")
        static let disabled = NSLocalizedString(
            "customers.error.analyticsDisabled",
            value: "Customer lists need WooCommerce Analytics, which is turned off for this store. " +
            "You can enable it here, or in your store admin under WooCommerce › Settings › Advanced › Features and then tap Retry.",
            comment: "Message shown when WooCommerce Analytics is turned off while loading customers")
        static let noPermission = NSLocalizedString(
            "customers.error.analyticsNoPermission",
            value: "Customer lists need WooCommerce Analytics, which isn't available on this store. " +
            "Ask a store administrator to turn it on in WooCommerce › Settings › Advanced › Features.",
            comment: "Message shown when the current user can't view the WooCommerce Analytics setting")
        static let unavailable = NSLocalizedString(
            "customers.error.analyticsUnavailable",
            value: "Customer lists need WooCommerce Analytics, which isn't available on this store right now. " +
            "Ask a store administrator to check that it's turned on.",
            comment: "Message shown when WooCommerce Analytics is unavailable while loading customers")
        static let genericErrorMessage = NSLocalizedString(
            "customers.error.generic",
            value: "Failed to fetch the customers data. Please try again later.",
            comment: "Generic customer loading error shown after a WooCommerce Analytics error")
        static let retry = NSLocalizedString(
            "customers.error.retry",
            value: "Retry",
            comment: "Retry action in the customer loading error state")
        static let enableAnalytics = NSLocalizedString(
            "customers.error.enableAnalytics",
            value: "Enable Analytics",
            comment: "Action to enable WooCommerce Analytics from the customer loading error state")
        static let confirmationTitle = NSLocalizedString(
            "customers.error.confirmationTitle",
            value: "Enable WooCommerce Analytics?",
            comment: "Confirmation title before enabling WooCommerce Analytics from the customer loading error state")
        static let confirmationMessage = NSLocalizedString(
            "customers.error.confirmationMessage",
            value: "This changes a setting for your whole store. It stays on until someone turns it off in " +
            "WooCommerce › Settings › Advanced › Features. Customers from the time Analytics was off may only show up after you import historical data in " +
            "WooCommerce › Analytics › Settings.",
            comment: "Explanation that enabling WooCommerce Analytics changes a store-wide setting")
        static let confirm = NSLocalizedString(
            "customers.error.confirm",
            value: "Enable",
            comment: "Confirmation action to enable WooCommerce Analytics")
        static let cancel = NSLocalizedString(
            "customers.error.cancel",
            value: "Cancel",
            comment: "Cancel action in the WooCommerce Analytics confirmation")

        static func message(for message: CustomerListErrorViewModel.Message) -> String {
            switch message {
            case .disabled:
                return disabled
            case .noPermission:
                return noPermission
            case .unavailable:
                return unavailable
            }
        }
    }
}

#if DEBUG

#Preview("Analytics disabled") {
    CustomerListErrorView(viewModel: .preview(state: .shown(.disabled)))
}

#Preview("Analytics setting unavailable") {
    CustomerListErrorView(viewModel: .preview(state: .shown(.noPermission)))
}

#Preview("Analytics unavailable") {
    CustomerListErrorView(viewModel: .preview(state: .shown(.unavailable)))
}

#Preview("Generic error") {
    CustomerListErrorView(viewModel: .preview(state: .generic))
}

#endif
