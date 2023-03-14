import SwiftUI

/// Hosting controller that wraps the `StoreOnboardingLaunchStoreView`.
final class StoreOnboardingLaunchStoreHostingController: UIHostingController<StoreOnboardingLaunchStoreView> {
    init(viewModel: StoreOnboardingLaunchStoreViewModel) {
        super.init(rootView: StoreOnboardingLaunchStoreView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTransparentNavigationBar()
    }
}

/// Shows a preview of the site with a CTA to launch store if applicable.
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

            // Readonly webview for the site.
            WebView(isPresented: .constant(true), url: viewModel.siteURL)
                .frame(height: Layout.webviewHeight * scale)
                .disabled(true)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                    .dividerStyle()


                // Launch store button.
                Button(Localization.launchStoreButton) {
                    Task { @MainActor in
                        try await viewModel.launchStore()
                    }
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isLaunchingStore))
                .padding(insets: Layout.buttonContainerPadding)
            }
            .background(Color(.systemBackground))
        }
        .navigationTitle(Localization.title)
    }
}

private extension StoreOnboardingLaunchStoreView {
    enum Layout {
        static let webviewHeight: CGFloat = 400
        static let buttonContainerPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
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
