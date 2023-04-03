import SwiftUI
import UIKit

/// Hosting controller to interact with UIKit.
///
final class FreeTrialSummaryHostingController: UIHostingController<FreeTrialSummaryView> {
    init() {
        super.init(rootView: FreeTrialSummaryView())
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


/// View to inform the benefits of a free trial
///
struct FreeTrialSummaryView: View {
    /// Free Trial feature representation
    ///
    struct Feature {
        let title: String
        let icon: UIImage
    }

    /// Free Trial Features
    ///
    static let features: [Feature] = [
        .init(title: Localization.Feature.premiumThemes, icon: .starOutlineImage()),
        .init(title: Localization.Feature.unlimitedProducts, icon: .productImage),
        .init(title: Localization.Feature.shippingLabels, icon: .shippingOutlineIcon),
        .init(title: Localization.Feature.ecommerceReports, icon: .ecommerceIcon),
        .init(title: Localization.Feature.paymentOptions, icon: .getPaidImage),
        .init(title: Localization.Feature.subscriptions, icon: .giftIcon),
        .init(title: Localization.Feature.advertising, icon: .megaphoneIcon),
        .init(title: Localization.Feature.marketing, icon: .emailOutlineIcon),
        .init(title: Localization.Feature.support, icon: .supportIcon),
        .init(title: Localization.Feature.backups, icon: .backupsIcon),
        .init(title: Localization.Feature.security, icon: .cloudOutlineImage),
        .init(title: Localization.Feature.launch, icon: .customizeDomainsImage)
    ]

    var body: some View {
        VStack(spacing: .zero) {
            // Main Content
            ScrollView {
                VStack(alignment: .leading, spacing: .zero) {

                    /// Align image to the right
                    HStack {
                        Spacer()
                        Image(uiImage: .freeTrialIllustration)
                    }
                    .padding([.trailing, .bottom], Layout.illustrationInset)

                    Text(Localization.launchInDays)
                        .bold()
                        .titleStyle()
                        .padding(.bottom, Layout.titleSpacing)

                    Text(Localization.weOfferEverything)
                        .secondaryBodyStyle()
                        .padding(.trailing, Layout.infoTrailingMargin)
                        .padding(.bottom, Layout.sectionsSpacing)

                    Text(Localization.tryItForDays)
                        .bold()
                        .secondaryTitleStyle()
                        .padding(.bottom, Layout.titleSpacing)

                    ForEach(Self.features, id: \.title) { feature in
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
                    print("Continue Pressed")
                } label: {
                    Text(Localization.tryItForFree)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding()

                Text(Localization.noCardRequired)
                    .subheadlineStyle()
                    .scenePadding(.bottom)
            }
            .background(Color(.listForeground(modal: false)))
        }
    }
}

private extension FreeTrialSummaryView {
    enum Localization {
        enum Feature {
            static let premiumThemes = NSLocalizedString("Premium Themes", comment: "Premium Themes title feature on the Free Trial Summary Screen")
            static let unlimitedProducts = NSLocalizedString("Unlimited products", comment: "Unlimited products title feature on the Free Trial Summary Screen")
            static let shippingLabels = NSLocalizedString("Shipping labels", comment: "Shipping labels title feature on the Free Trial Summary Screen")
            static let ecommerceReports = NSLocalizedString("Ecommerce reports", comment: "Ecommerce reports title feature on the Free Trial Summary Screen")
            static let paymentOptions = NSLocalizedString("Multiple payment options",
                                                          comment: "Multiple payment options title feature on the Free Trial Summary Screen")
            static let subscriptions = NSLocalizedString("Subscriptions & product kits",
                                                         comment: "Subscriptions & product kits title feature on the Free Trial Summary Screen")
            static let advertising = NSLocalizedString("Social advertising", comment: "Social advertising title feature on the Free Trial Summary Screen")
            static let marketing = NSLocalizedString("Email marketing", comment: "Email marketing title feature on the Free Trial Summary Screen")
            static let support = NSLocalizedString("24/7 support", comment: "24/7 support title feature on the Free Trial Summary Screen")
            static let backups = NSLocalizedString("Auto updates & backups", comment: "Auto updates & backups title feature on the Free Trial Summary Screen")
            static let security = NSLocalizedString("Site security", comment: "Site security title feature on the Free Trial Summary Screen")
            static let launch = NSLocalizedString("Fast to launch", comment: "Fast to launch title feature on the Free Trial Summary Screen")
        }

        static let launchInDays = NSLocalizedString("Launch in days, \ngrow for years",
                                                    comment: "Main title for the free trial summary screen. Be aware of the break line")
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
    }
}


struct FreeTrialSummaryView_Preview: PreviewProvider {
    static var previews: some View {
        FreeTrialSummaryView()
    }
}
