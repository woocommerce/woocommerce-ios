import Foundation
import SwiftUI

struct FullFeatureListGroups {
    public let title: String
    public let essentialFeatures: [String]
    public let performanceFeatures: [String]
}

struct FullFeatureListViewModel {
    static func hardcodedFullFeatureList() -> [FullFeatureListGroups] {
        return [
            FullFeatureListGroups(title: Localization.yourStoreFeatureTitle,
                                  essentialFeatures: [
                                    Localization.wooCommerceStoreText,
                                    Localization.wooCommerceMobileAppText,
                                    Localization.wordPressCMSText,
                                    Localization.wordPressMobileAppText,
                                    Localization.freeSSLCertificateText,
                                    Localization.generousStorageText,
                                    Localization.automatedBackupQuickRestoreText,
                                    Localization.adFreeExperienceText,
                                    Localization.unlimitedAdminAccountsText,
                                    Localization.liveChatSupportText,
                                    Localization.emailSupportText,
                                    Localization.premiumThemesIncludedText,
                                    Localization.salesReportsText,
                                    Localization.googleAnalyticsText,
                                  ],
                                  performanceFeatures: []
                                 ),
            FullFeatureListGroups(title: Localization.productsFeatureTitle,
                                  essentialFeatures: [
                                    Localization.listUnlimitedProducts,
                                    Localization.giftCards,
                                    Localization.listProductsByBrand,
                                  ],
                                  performanceFeatures: [
                                    "Min/Max order quantity",
                                    "Product Bundles",
                                    "Custom product kits",
                                    "Product recommendations"
                                  ]),
            FullFeatureListGroups(title: Localization.paymentsFeatureTitle,
                                  essentialFeatures: [
                                    Localization.integratedPayments,
                                    Localization.internationalPayments,
                                    Localization.automatedSalesTaxes,
                                    Localization.acceptLocalPayments,
                                    Localization.recurringPayments,
                                  ],
                                  performanceFeatures: []),

            FullFeatureListGroups(title: Localization.marketingAndEmailFeatureTitle,
                                  essentialFeatures: [
                                    Localization.promoteOnTikTok,
                                    Localization.syncWithPinterest,
                                    Localization.connectWithFacebook,
                                    Localization.advancedSeoTools,
                                    Localization.advertiseOnGoogle,
                                    Localization.customOrderEmails,
                                  ],
                                  performanceFeatures: [
                                    "Back in stock emails",
                                    "Marketing automation",
                                    "Abandoned cart recovery",
                                    "Referral programs",
                                    "Customer birthday emails",
                                    "Loyalty points programs"
                                  ]),

            FullFeatureListGroups(title: Localization.shippingFeatureTitle,
                                  essentialFeatures: [
                                    Localization.shipmentTracking,
                                    Localization.liveShippingRates,
                                    Localization.printShippingLabels
                                    ],
                                  performanceFeatures: [
                                    "Discounted shipping²"]),
        ]
    }
}

private extension FullFeatureListViewModel {
    struct Localization {
        static let yourStoreFeatureTitle = NSLocalizedString(
            "Your Store",
            comment: "The title of one of the feature groups offered with paid plans")

        static let productsFeatureTitle = NSLocalizedString(
            "Products",
            comment: "The title of one of the feature groups offered with paid plans")

        static let paymentsFeatureTitle = NSLocalizedString(
            "Payments",
            comment: "The title of one of the feature groups offered with paid plans")

        static let marketingAndEmailFeatureTitle = NSLocalizedString(
            "Marketing & Email",
            comment: "The title of one of the feature groups offered with paid plans")

        static let shippingFeatureTitle = NSLocalizedString(
            "Shipping",
            comment: "The title of one of the feature groups offered with paid plans")

        static let wooCommerceStoreText = NSLocalizedString(
            "WooCommerce store",
            comment: "The title of one of the features offered with the Essential plan")

        static let wooCommerceMobileAppText = NSLocalizedString(
            "WooCommerce mobile app",
            comment: "The title of one of the features offered with the Essential plan")

        static let wordPressCMSText = NSLocalizedString(
            "WordPress CMS",
            comment: "The title of one of the features offered with the Essential plan")

        static let wordPressMobileAppText = NSLocalizedString(
            "WordPress mobile app",
            comment: "The title of one of the features offered with the Essential plan")

        static let freeSSLCertificateText = NSLocalizedString(
            "Free SSL certificate",
            comment: "The title of one of the features offered with the Essential plan")

        static let generousStorageText = NSLocalizedString(
            "Generous storage",
            comment: "The title of one of the features offered with the Essential plan")

        static let automatedBackupQuickRestoreText = NSLocalizedString(
            "Automated backup + quick restore",
            comment: "The title of one of the features offered with the Essential plan")

        static let adFreeExperienceText = NSLocalizedString(
            "Ad-free experience",
            comment: "The title of one of the features offered with the Essential plan")

        static let unlimitedAdminAccountsText = NSLocalizedString(
            "Unlimited admin accounts",
            comment: "The title of one of the features offered with the Essential plan")

        static let liveChatSupportText = NSLocalizedString(
            "Live chat support",
            comment: "The title of one of the features offered with the Essential plan")

        static let emailSupportText = NSLocalizedString(
            "Email support",
            comment: "The title of one of the features offered with the Essential plan")

        static let premiumThemesIncludedText = NSLocalizedString(
            "Premium themes included",
            comment: "The title of one of the features offered with the Essential plan")

        static let salesReportsText = NSLocalizedString(
            "Sales reports",
            comment: "The title of one of the features offered with the Essential plan")

        static let googleAnalyticsText = NSLocalizedString(
            "Google Analytics",
            comment: "The title of one of the features offered with the Essential plan")

        static let listUnlimitedProducts = NSLocalizedString(
            "List unlimited products",
            comment: "The title of one of the features offered with the Essential plan")

        static let giftCards = NSLocalizedString(
            "Gift cards",
            comment: "The title of one of the features offered with the Essential plan")

        static let listProductsByBrand = NSLocalizedString(
            "List products by brand",
            comment: "The title of one of the features offered with the Essential plan")

        static let integratedPayments = NSLocalizedString(
            "Integrated payments",
            comment: "The title of one of the features offered with the Essential plan")

        static let internationalPayments = NSLocalizedString(
            "International payments'",
            comment: "The title of one of the features offered with the Essential plan")

        static let automatedSalesTaxes = NSLocalizedString(
            "Automated sales taxes",
            comment: "The title of one of the features offered with the Essential plan")

        static let acceptLocalPayments = NSLocalizedString(
            "Accept local payments'",
            comment: "The title of one of the features offered with the Essential plan")

        static let recurringPayments = NSLocalizedString(
            "Recurring payments'",
            comment: "The title of one of the features offered with the Essential plan")
        static let promoteOnTikTok = NSLocalizedString(
            "Promote on TikTok",
            comment: "The title of one of the features offered with the Essential plan")

        static let syncWithPinterest = NSLocalizedString(
            "Sync with Pinterest",
            comment: "The title of one of the features offered with the Essential plan")

        static let connectWithFacebook = NSLocalizedString(
            "Connect with Facebook",
            comment: "The title of one of the features offered with the Essential plan")

        static let advancedSeoTools = NSLocalizedString(
            "Advanced SEO tools",
            comment: "The title of one of the features offered with the Essential plan")

        static let advertiseOnGoogle = NSLocalizedString(
            "Advertise on Google",
            comment: "The title of one of the features offered with the Essential plan")

        static let customOrderEmails = NSLocalizedString(
            "Custom order emails",
            comment: "The title of one of the features offered with the Essential plan")

        static let shipmentTracking = NSLocalizedString(
            "Shipment tracking",
            comment: "The title of one of the features offered with the Essential plan")

        static let liveShippingRates = NSLocalizedString(
            "Live shipping rates",
            comment: "The title of one of the features offered with the Essential plan")

        static let printShippingLabels = NSLocalizedString(
            "Print shipping labels²",
            comment: "The title of one of the features offered with the Essential plan")
    }
}

struct FullFeatureListView: View {
    @Environment(\.presentationMode) var presentationMode

    var featureListGroups = FullFeatureListViewModel.hardcodedFullFeatureList()

    var body: some View {
        ScrollView() {
            VStack(alignment: .leading, spacing: FullFeatureListView.Layout.featureListSpacing) {
                ForEach(featureListGroups, id: \.title) { featureList in
                    Text(featureList.title)
                        .font(.title)
                        .bold()
                        .padding(.bottom)
                    ForEach(featureList.essentialFeatures, id: \.self) { feature in
                        Text(feature)
                            .font(.body)
                    }
                    ForEach(featureList.performanceFeatures, id: \.self) { feature in
                        HStack {
                            Text(feature)
                                .font(.body)
                            Image(systemName: "star.fill")
                                .foregroundColor(.withColorStudio(name: .wooCommercePurple, shade: .shade50))
                                .font(.footnote)
                        }
                    }
                    Divider()
                        .padding(.top)
                        .padding(.bottom)
                    HStack {
                        Image(systemName: "star.fill")
                        Text(Localization.performanceOnlyText)
                    }
                    .font(.footnote)
                    .foregroundColor(.withColorStudio(name: .wooCommercePurple, shade: .shade50))
                    .padding(.bottom)
                    .renderedIf(featureList.performanceFeatures.isNotEmpty)
                }
            }
            .padding(.horizontal)
            .background(Color(.white))
            .cornerRadius(Layout.featureListCornerRadius)
            VStack(alignment: .leading, spacing: Layout.featureListSpacing) {
                Text(Localization.paymentsDisclaimerText)
                    .font(.caption)
                Text(Localization.pluginsDisclaimerText)
                    .font(.caption)
            }
            .background(Color(.secondarySystemBackground))
        }
        .padding()
        .navigationTitle(Localization.featureListTitleText)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
        })
        .background(Color(.secondarySystemBackground))
    }
}

private extension FullFeatureListView {
    struct Localization {
        static let featureListTitleText = NSLocalizedString(
            "Full Feature List",
            comment: "")

        static let performanceOnlyText = NSLocalizedString(
            "Performance plan only",
            comment: "")

        static let paymentsDisclaimerText = NSLocalizedString(
            "1. Available as standard in WooCommerce Payments (restrictions apply)." +
            "Additional extensions may be required for other payment providers." ,
            comment: "")

        static let pluginsDisclaimerText = NSLocalizedString(
            "2. Only available in the U.S. – an additional extension will be required for other countries.",
            comment: "")
    }
    
    struct Layout {
        static let featureListSpacing: CGFloat = 8.0
        static let featureListCornerRadius: CGFloat = 10.0
    }
}
