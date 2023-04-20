import SwiftUI

/// Hosting controller for `FreeTrialBanner`.
///
final class FreeTrialBannerHostingViewController: UIHostingController<FreeTrialBanner> {
    /// Designated initializer.
    ///
    init(mainText: String, onUpgradeNowTapped: @escaping () -> Void) {
        super.init(rootView: FreeTrialBanner(mainText: mainText, onUpgradeNowTapped: onUpgradeNowTapped))
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

    /// Text to be rendered next to the info image.
    ///
    let mainText: String

    /// Closure invoked when the merchants taps on the `Upgrade Now` button.
    ///
    let onUpgradeNowTapped: () -> Void

    var body: some View {
        VStack(spacing: .zero) {
            Divider()

            HStack(alignment: .center) {
                Image(uiImage: .infoOutlineImage)
                    .accessibilityHidden(true)

                AdaptiveStack(verticalAlignment: .center, spacing: Layout.spacing) {
                    Text(mainText)
                        .bodyStyle()

                    Text(Localization.upgradeNow)
                        .underline(true)
                        .linkStyle()
                        .onTapGesture(perform: onUpgradeNowTapped)
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
        static let upgradeNow = NSLocalizedString("Upgrade Now", comment: "Title on the button to upgrade a free trial plan.")
    }
}

struct FreeTrial_Preview: PreviewProvider {
    static var previews: some View {
        FreeTrialBanner(mainText: "Your Free trial has ended", onUpgradeNowTapped: { })
            .previewLayout(.sizeThatFits)
    }
}
