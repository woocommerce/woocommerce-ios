import SwiftUI

/// Hosting controller for `StorePlanBanner`.
///
final class StorePlanBannerHostingViewController: UIHostingController<StorePlanBanner> {
    /// Designated initializer.
    ///
    init(mainText: String) {
        super.init(rootView: StorePlanBanner(mainText: mainText))
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
    let mainText: String

    var body: some View {
        VStack(spacing: .zero) {
            Divider()

            HStack(alignment: .center) {
                Image(uiImage: .infoOutlineImage)
                    .accessibilityHidden(true)

                AdaptiveStack(verticalAlignment: .center, spacing: Layout.spacing) {
                    Text(mainText)
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
        StorePlanBanner(mainText: "Your Free trial has ended")
            .previewLayout(.sizeThatFits)
    }
}
