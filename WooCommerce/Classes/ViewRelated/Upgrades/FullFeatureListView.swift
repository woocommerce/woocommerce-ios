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
                                    "WooCommerce store",
                                    "WooCommerce mobile app",
                                    "WordPress CMS",
                                    "WordPress mobile app",
                                    "Free SSL certificate",
                                    "Generous storage",
                                    "Automated backup + quick restore",
                                    "Ad-free experience",
                                    "Unlimited admin accounts",
                                    "Live chat support",
                                    "Email support",
                                    "Premium themes included",
                                    "Sales reports",
                                    "Google Analytics"
                                  ],
                                  performanceFeatures: []
                                 ),
            FullFeatureListGroups(title: Localization.productsFeatureTitle,
                                  essentialFeatures: [
                                    "List unlimited products",
                                    "Gift cards",
                                    "List products by brand",
                                  ],
                                  performanceFeatures: [
                                    "Min/Max order quantity",
                                    "Product Bundles",
                                    "Custom product kits",
                                    "Product recommendations"
                                  ]),
            FullFeatureListGroups(title: Localization.paymentsFeatureTitle,
                                  essentialFeatures: [
                                    "Integrated payments",
                                    "International payments'",
                                    "Automated sales taxes",
                                    "Accept local payments'",
                                    "Recurring payments'"
                                  ],
                                  performanceFeatures: []),

            FullFeatureListGroups(title: Localization.marketingAndEmailFeatureTitle,
                                  essentialFeatures: [
                                  "Promote on TikTok",
                                  "Sync with Pinterest",
                                  "Connect with Facebook",
                                  "Advanced SEO tools",
                                  "Advertise on Google",
                                  "Custom order emails",
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
                                  "Shipment tracking",
                                  "Live shipping rates",
                                  "Print shipping labels²"],
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
        
        static let WooCommerceStore = NSLocalizedString(
            "WooCommerce store",
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
