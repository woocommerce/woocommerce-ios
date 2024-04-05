import SwiftUI

/// Hosting controller for `StorePlanBanner`.
///
final class StorePlanBannerHostingViewController: UIHostingController<StorePlanBanner> {
    /// Designated initializer.
    ///
    init(text: String) {
        super.init(rootView: StorePlanBanner(text: text))
    }

    /// Needed for protocol conformance.
    ///
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Store Plan Banner. To be used inside the Dashboard.
///
struct StorePlanBanner: View {
    /// Text to be rendered next to the info image.
    ///
    let text: String

    var body: some View {
        VStack(spacing: .zero) {
            Divider()

            HStack(alignment: .center) {
                Image(uiImage: .infoOutlineImage)
                    .accessibilityHidden(true)

                AdaptiveStack(verticalAlignment: .center, spacing: Layout.spacing) {
                    Text(text)
                        .bodyStyle()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
        }
        .background(Color(.bannerBackground))
    }
}

// MARK: Definitions
extension StorePlanBanner {
    enum Layout {
        static let spacing: CGFloat = 6.0
    }

    enum Localization {
        static let learnMore = NSLocalizedString("Learn more", comment: "Title on the button to learn more about the free trial plan.")
    }
}

struct StorePlanBanner_Preview: PreviewProvider {
    static var previews: some View {
        StorePlanBanner(text: "Your Free trial has ended")
            .previewLayout(.sizeThatFits)
    }
}
