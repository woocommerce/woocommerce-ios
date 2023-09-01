import SwiftUI

/// Hosting controller that wraps the `StoreOnboardingStoreLaunchedView`.
final class StoreOnboardingStoreLaunchedHostingController: UIHostingController<StoreOnboardingStoreLaunchedView> {
    init(siteURL: URL, onContinue: @escaping () -> Void) {
        super.init(rootView: StoreOnboardingStoreLaunchedView(siteURL: siteURL))
        rootView.onContinue = onContinue
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Shows a preview of a launched store from store onboarding with a CTA to share the URL.
struct StoreOnboardingStoreLaunchedView: View {
    /// Set in the hosting controller.
    var onContinue: () -> Void = {}

    /// URL of the launched site.
    let siteURL: URL

    @State private var showsShareSheet: Bool = false

    // Tracks the scale of the view due to accessibility changes.
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: Layout.textAndPreviewSpacing) {
                VStack(alignment: .center, spacing: Layout.defaultSpacing) {
                    // Title label.
                    HStack(alignment: .center, spacing: Layout.titleAndCircleSpacing) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: Layout.circleDimension * scale, height: Layout.circleDimension * scale)
                        Text(Localization.title)
                            .fontWeight(.bold)
                            .titleStyle()
                    }

                    // URL label.
                    Text(siteURL.absoluteString.trimHTTPScheme())
                        .underline()
                        .foregroundColor(.init(.textSubtle))
                        .captionStyle()
                }

                // Readonly webview for the launched site.
                SitePreviewView(siteURL: siteURL)
            }
            .padding(Layout.contentPadding)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                    .dividerStyle()

                VStack(spacing: Layout.defaultSpacing) {
                    // Share button.
                    Button(Localization.shareButtonTitle) {
                        showsShareSheet = true
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    // Continue button.
                    Button(Localization.continueButtonTitle) {
                        onContinue()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(insets: Layout.buttonContainerPadding)
            }
            .background(Color(.systemBackground))
        }
        .shareSheet(isPresented: $showsShareSheet) {
            ShareSheet(activityItems: [siteURL])
        }
        .navigationBarHidden(true)
    }
}

private extension StoreOnboardingStoreLaunchedView {
    enum Layout {
        static let contentPadding: EdgeInsets = .init(top: 38, leading: 16, bottom: 16, trailing: 16)
        static let buttonContainerPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let defaultSpacing: CGFloat = 16
        static let textAndPreviewSpacing: CGFloat = 33
        static let titleAndCircleSpacing: CGFloat = 14
        static let circleDimension: CGFloat = 12
    }

    enum Localization {
        static let title = NSLocalizedString(
            "Your store is live!",
            comment: "Title of the store onboarding launched store screen."
        )
        static let shareButtonTitle = NSLocalizedString(
            "Share URL",
            comment: "Title of the primary button on the store onboarding launched store screen."
        )
        static let continueButtonTitle = NSLocalizedString(
            "Back to My Store",
            comment: "Title of the secondary button on the store onboarding launched store screen."
        )
    }
}

struct StoreOnboardingStoreLaunchedView_Previews: PreviewProvider {
    static var previews: some View {
        StoreOnboardingStoreLaunchedView(siteURL: URL(string: "https://woocommerce.com")!)
    }
}
