import SwiftUI
import UIKit

/// Hosting controller to interact with UIKit.
///
final class FreeTrialSummaryHostingController: UIHostingController<FreeTrialSummaryView> {
    init(onClose: (() -> ())? = nil, onContinue: (() -> ())? = nil) {
        super.init(rootView: FreeTrialSummaryView(onClose: onClose, onContinue: onContinue))
        modalPresentationStyle = .fullScreen
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


/// View to inform the benefits of a free trial
///
struct FreeTrialSummaryView: View {
    /// Closure invoked when the close button is pressed
    ///
    let onClose: (() -> ())?

    /// Closure invoked when the "Try For Free"  button is pressed
    ///
    let onContinue: (() -> ())?

    var body: some View {
        VStack(spacing: .zero) {
            // Main Content
            ScrollView {
                VStack(alignment: .leading, spacing: .zero) {

                    // Illustration header & Close Button
                    HStack(alignment: .top) {
                        Button {
                            onClose?()
                        } label: {
                            Image(uiImage: .closeButton)
                                .foregroundColor(Color(.textSubtle))
                        }

                        Spacer()

                        Image(uiImage: .freeTrialIllustration)
                    }
                    .padding([.trailing, .bottom], Layout.illustrationInset)

                    // Title
                    Text(Localization.launchInDays)
                        .bold()
                        .titleStyle()
                        .padding(.bottom, Layout.titleSpacing)
                        .padding(.trailing, Layout.estimatedIllustrationWidth)

                    // Description
                    Text(Localization.weOfferEverything)
                        .secondaryBodyStyle()
                        .padding(.trailing, Layout.infoTrailingMargin)
                        .padding(.bottom, Layout.sectionsSpacing)

                    // Features
                    Text(Localization.tryItForDays)
                        .bold()
                        .secondaryTitleStyle()
                        .padding(.bottom, Layout.titleSpacing)

                    ForEach(FreeTrialFeatures.features, id: \.title) { feature in
                        HStack {
                            Image(uiImage: feature.icon)
                                .foregroundColor(Color(uiColor: .accent))

                            Text(feature.title)
                                .foregroundColor(Color(.text))
                                .calloutStyle()
                        }
                        .padding(.bottom, Layout.featureSpacing)
                    }

                    // WPCom logo
                    HStack {
                        Text(Localization.poweredBy)
                            .foregroundColor(Color(uiColor: .textSubtle))
                            .captionStyle()

                        Image(uiImage: .wpcomLogoImage(tintColor: .textSubtle))

                    }
                }
                .padding()
            }
            .background(Color(.listBackground))

            // Continue Footer
            VStack() {
                Divider()

                Button {
                    onContinue?()
                } label: {
                    Text(Localization.tryItForFree)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding()

                Text(Localization.noCardRequired)
                    .subheadlineStyle()
            }
            .background(Color(.listForeground(modal: false)))
        }
    }
}

private extension FreeTrialSummaryView {
    enum Localization {
        static let launchInDays = NSLocalizedString("Launch in days, grow for years", comment: "Main title for the free trial summary screen.")
        static let weOfferEverything = NSLocalizedString("We offer everything you need to build and grow an online store, " +
                                                         "powered by WooCommerce and hosted on WordPress.com.",
                                                         comment: "Main description for the free trial summary screen")
        static let tryItForDays = NSLocalizedString("Try it free for 14 days.", comment: "Title for the features list in the free trial Summary Screen")
        static let poweredBy = NSLocalizedString("Powered by", comment: "Text next to the WPCom logo in the free trial summary screen")
        static let tryItForFree = NSLocalizedString("Try For Free", comment: "Text in the button to continue with the free trial plan")
        static let noCardRequired = NSLocalizedString("No credit card required.", comment: "Text indicated that no card is needed for a free trial")
    }

    enum Layout {
        static let featureSpacing = 18.0
        static let titleSpacing = 16.0
        static let sectionsSpacing = 32.0
        static let infoTrailingMargin = 8.0
        static let illustrationInset = -32.0
        static let estimatedIllustrationWidth = 150.0
    }
}


struct FreeTrialSummaryView_Preview: PreviewProvider {
    static var previews: some View {
        FreeTrialSummaryView(onClose: nil, onContinue: nil)
    }
}
