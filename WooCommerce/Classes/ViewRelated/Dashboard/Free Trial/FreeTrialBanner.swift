import SwiftUI

/// Hosting controller for `FreeTrialBanner`.
///
final class FreeTrialBannerHostingViewController: UIHostingController<FreeTrialBanner> {
    /// Designated initializer.
    ///
    init(actionText: String, mainText: String, onLearnMoreTapped: @escaping () -> Void) {
        super.init(rootView: FreeTrialBanner(actionText: actionText,
                                             mainText: mainText,
                                             onLearnMoreTapped: onLearnMoreTapped))
    }

    /// Needed for protocol conformance.
    ///
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Free Trial Banner. To be used inside the Dashboard.
///
struct FreeTrialBanner: View {

    /// Text to be rendered as the banner action button
    ///
    let actionText: String

    /// Text to be rendered next to the info image.
    ///
    let mainText: String

    /// Closure invoked when the merchants taps on the `Learn More` button.
    ///
    let onLearnMoreTapped: () -> Void

    var body: some View {
        VStack(spacing: .zero) {
            Divider()

            HStack(alignment: .center) {
                Image(uiImage: .infoOutlineImage)
                    .accessibilityHidden(true)

                AdaptiveStack(verticalAlignment: .center, spacing: Layout.spacing) {
                    Text(mainText)
                        .bodyStyle()

                    Text(actionText)
                        .underline(true)
                        .linkStyle()
                        .onTapGesture(perform: onLearnMoreTapped)
                        .accessibilityAddTraits(.isButton)
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
extension FreeTrialBanner {
    enum Layout {
        static let spacing: CGFloat = 6.0
    }

    enum Localization {
        static let learnMore = NSLocalizedString("Learn more", comment: "Title on the button to learn more about the free trial plan.")
    }
}

struct FreeTrial_Preview: PreviewProvider {
    static var previews: some View {
        FreeTrialBanner(actionText: "Upgrade now", mainText: "Your Free trial has ended", onLearnMoreTapped: { })
            .previewLayout(.sizeThatFits)
    }
}
