import SwiftUI

/// Hosting controller for `FreeTrialBanner`.
///
final class FreeTrialBannerHostingViewController: UIHostingController<FreeTrialBanner> {

    /// Designated initializer.
    ///
    init() {
        super.init(rootView: FreeTrialBanner())
        self.view.backgroundColor = .wooCommercePurple(.shade5)
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

    var body: some View {
        HStack {
            Image(uiImage: .infoOutlineImage)

            HStack(spacing: 6) {
                Text("Your trial has ended.")
                    .bodyStyle()

                Text("Upgrade Now")
                    .underline(true)
                    .linkStyle()
                    .onTapGesture {
                        print("Upgrade Now Pressed")
                    }
            }
        }
        .padding()
        .background(Color(.wooCommercePurple(.shade5)))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FreeTrial_Preview: PreviewProvider {
    static var previews: some View {
        FreeTrialBanner()
            .previewLayout(.sizeThatFits)
    }
}
