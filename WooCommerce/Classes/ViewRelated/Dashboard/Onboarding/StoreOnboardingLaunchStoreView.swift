import SwiftUI

struct StoreOnboardingLaunchStoreView: View {
    // Tracks the scale of the view due to accessibility changes.
    @ScaledMetric private var scale: CGFloat = 1.0

    @ObservedObject private var viewModel: StoreOnboardingLaunchStoreViewModel

    init(viewModel: StoreOnboardingLaunchStoreViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            #warning("TODO: 9122 - show upsell banner when the launch store action requires an upgraded plan")

            // Readonly webview for the new site.
            WebView(isPresented: .constant(true), url: viewModel.siteURL)
                .frame(height: 400 * scale)
                .disabled(true)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                    .frame(height: 1)
                    .foregroundColor(Color(.separator))

                VStack(spacing: 16) {
                    // Launch store button.
                    Button(Localization.launchStoreButton) {
                        Task { @MainActor in
                            try await viewModel.launchStore()
                        }
                    }
                    .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isLaunchingStore))
                }
                .padding(insets: Layout.buttonContainerPadding)
            }
            .background(Color(.systemBackground))
        }
    }
}

private extension StoreOnboardingLaunchStoreView {
    enum Layout {
        static let contentPadding: EdgeInsets = .init(top: 38, leading: 16, bottom: 16, trailing: 16)
        static let buttonContainerPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let webviewHorizontalPadding: EdgeInsets = .init(top: 0, leading: 44, bottom: 0, trailing: 44)
    }

    enum Localization {
        static let title = NSLocalizedString(
            "Preview",
            comment: "Title of the store onboarding > launch store screen."
        )
        static let launchStoreButton = NSLocalizedString(
            "Publish My Store",
            comment: "Title of the primary button on the store onboarding > launch store screen to publish a store."
        )
    }
}

struct StoreOnboardingLaunchStoreView_Previews: PreviewProvider {
    static var previews: some View {
        StoreOnboardingLaunchStoreView(viewModel: .init(siteURL: .init(string: "https://woocommerce.com")!))
    }
}
