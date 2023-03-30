import SwiftUI
import enum Yosemite.SiteLaunchError

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
            freeTrialBanner
                .renderedIf(viewModel.state == .needsPlanUpgrade)

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
                        await viewModel.launchStore()
                    }
                }
                .if((viewModel.state == .launchingStore || viewModel.state == .readyToPublish)) {
                    $0.buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.state == .launchingStore))
                }
                .if(viewModel.state == .needsPlanUpgrade) {
                    $0.buttonStyle(PrimaryButtonStyle()).disabled(true)
                }
                .padding(insets: Layout.buttonContainerPadding)
                .renderedIf(viewModel.state != .checkingSitePlan)
            }
            .background(Color(.systemBackground))
        }
        .alert(item: $viewModel.error) { error in
            switch error {
            case .alreadyLaunched:
                return Alert(title: Text(error.title),
                             message: Text(error.message),
                             dismissButton: .default(Text(error.dismissTitle)))
            case .unexpected:
                return Alert(title: Text(error.title),
                             message: Text(error.message),
                             primaryButton: .default(Text(error.dismissTitle)),
                             secondaryButton: .default(Text(error.retryTitle ?? ""), action: {
                    Task { @MainActor in
                        await viewModel.launchStore()
                    }
                }))
            }
        }
        .navigationTitle(Localization.title)
        .task {
            await viewModel.checkEligibilityToPublishStore()
        }
    }
}

private extension StoreOnboardingLaunchStoreView {
    var freeTrialBanner: some View {
        HStack(alignment: .top, spacing: Layout.FreeTrialBanner.horizontalSpacing) {
            Image(uiImage: .infoOutlineImage)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(Color(.withColorStudio(.green, shade: .shade80)))
                .frame(width: Layout.FreeTrialBanner.infoIconSize.width * scale, height: Layout.FreeTrialBanner.infoIconSize.height * scale)

            AttributedText(viewModel.upgradePlanAttributedString)
        }
        .padding(insets: Layout.FreeTrialBanner.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.bannerBackground))
        .onTapGesture {
            viewModel.didTapUpgrade()
        }
    }

    enum Layout {
        static let webviewHeight: CGFloat = 400
        static let buttonContainerPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        enum FreeTrialBanner {
            static let infoIconSize: CGSize = .init(width: 24, height: 24)
            static let horizontalSpacing: CGFloat = 16
            static let padding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        }
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

extension SiteLaunchError: Identifiable {
    public var id: String {
        title
    }
}

private extension SiteLaunchError {
    var title: String {
        switch self {
        case .alreadyLaunched:
            return NSLocalizedString(
                "Could not launch your store",
                comment: "Title of the alert when the site cannot be launched from store onboarding > launch store screen."
            )
        case .unexpected:
            return NSLocalizedString(
                "Unexpected error",
                comment: "Title of the alert when the site cannot be launched from store onboarding > launch store screen."
            )
        }
    }

    var message: String {
        switch self {
        case .alreadyLaunched:
            return NSLocalizedString(
                "We found that the store has already launched.",
                comment: "Message of the alert when the site cannot be launched from store onboarding > launch store screen."
            )
        case .unexpected:
            return NSLocalizedString(
                "Oops, some unexpected errors happened.",
                comment: "Message of the alert when the site cannot be launched from store onboarding > launch store screen."
            )
        }
    }

    var dismissTitle: String {
        switch self {
        case .alreadyLaunched:
            return NSLocalizedString("OK",
                comment: "Title of the alert dismiss action when the site cannot be launched from store onboarding > launch store screen."
            )
        case .unexpected:
            return NSLocalizedString(
                "Cancel",
                comment: "Title of the alert dismiss action when the site cannot be launched from store onboarding > launch store screen."
            )
        }
    }

    var retryTitle: String? {
        switch self {
        case .alreadyLaunched:
            return nil
        case .unexpected:
            return NSLocalizedString(
                "Try again",
                comment: "Title of the try again action when the site cannot be launched from store onboarding > launch store screen."
            )
        }
    }
}

struct StoreOnboardingLaunchStoreView_Previews: PreviewProvider {
    static var previews: some View {
        StoreOnboardingLaunchStoreView(viewModel: .init(siteURL: .init(string: "https://woocommerce.com")!, siteID: 0, onLaunch: {}, onUpgradeTapped: {}))
    }
}
