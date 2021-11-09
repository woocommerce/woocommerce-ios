import SwiftUI

/// Hosting controller wrapper for `JetpackBenefitsBanner`
///
final class JetpackBenefitsBannerHostingController: UIHostingController<JetpackBenefitsBanner> {
    init() {
        super.init(rootView: JetpackBenefitsBanner())
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Actions are set in a separate function because most of the time, they will require to access `self` to be able to present new view controllers.
    ///
    func setActions(tapAction: @escaping () -> Void, dismissAction: @escaping () -> Void) {
        rootView.tapAction = tapAction
        rootView.dismissAction = dismissAction
    }
}

/// A banner about Jetpack benefits that can be tapped to show more details or dismiss.
struct JetpackBenefitsBanner: View {
    /// Closure invoked when the banner is tapped
    ///
    var tapAction: () -> Void = {}

    /// Closure invoked when the dismiss button is tapped
    ///
    var dismissAction: () -> Void = {}

    // Tracks the scale of the view due to accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        Group {
            HStack(spacing: Layout.horizontalSpacing) {
                Image("icon-jetpack-gray")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color(.jetpackGreen))
                    .frame(width: Layout.iconDimension * scale, height: Layout.iconDimension * scale)
                VStack(alignment: .leading, spacing: Layout.verticalTextSpacing) {
                    Text(Localization.title)
                        .foregroundColor(.white)
                        .bodyStyle()
                    Text(Localization.subtitle)
                        .foregroundColor(Color(.gray(.shade30)))
                        .bodyStyle()
                }
                Spacer()
                Button(action: dismissAction) {
                    Image(uiImage: .closeButton)
                        .foregroundColor(Color(.gray(.shade30)))
                }
            }
            .padding(insets: Layout.padding)
        }
        .gesture(
            TapGesture()
                .onEnded { _ in
                    self.tapAction()
                }
        )
        .background(Color(.jetpackBenefitsBackground))
        .fixedSize(horizontal: false, vertical: true)
    }
}

private extension JetpackBenefitsBanner {
    enum Localization {
        static let title = NSLocalizedString("Get the full experience with Jetpack", comment: "Title of the Jetpack benefits banner.")
        static let subtitle = NSLocalizedString("See the benefits", comment: "Subtitle of the Jetpack benefits banner.")
    }

    enum Layout {
        static let padding = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let iconDimension = CGFloat(24)
        static let horizontalSpacing = CGFloat(10)
        static let verticalTextSpacing = CGFloat(5)
    }
}

struct JetpackBenefitsBanner_Previews: PreviewProvider {
    static var previews: some View {
        JetpackBenefitsBanner()
            .preferredColorScheme(.dark)
            .environment(\.sizeCategory, .extraExtraLarge)
        JetpackBenefitsBanner()
            .preferredColorScheme(.light)
            .environment(\.sizeCategory, .extraExtraLarge)
    }
}
