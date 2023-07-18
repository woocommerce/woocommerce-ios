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
            FullFeatureListGroups(title: "Your Store",
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
            FullFeatureListGroups(title: "Products",
                                  essentialFeatures: [
                                    "List unlimited products",
                                    "Gift cards",
                                  ],
                                  performanceFeatures: [
                                    "Min/Max order quantity",
                                    "Product Bundles",
                                    "Custom product kits",
                                    "List products by brand",
                                    "Product recommendations"
                                  ]),
            FullFeatureListGroups(title: "Payments",
                                  essentialFeatures: [
                                    "Integrated payments",
                                    "International payments'",
                                    "Automated sales taxes",
                                    "Accept local payments'",
                                    "Recurring payments'"
                                  ],
                                  performanceFeatures: []),

            FullFeatureListGroups(title: "Marketing & Email",
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

            FullFeatureListGroups(title: "Shipping",
                                  essentialFeatures: [
                                  "Shipment tracking",
                                  "Live shipping rates",
                                  "Discounted shipping²",
                                  "Print shipping labels²"],
                                  performanceFeatures: []),
        ]
    }
}

struct FullFeatureListView: View {
    @Environment(\.presentationMode) var presentationMode

    var featureListGroups = FullFeatureListViewModel.hardcodedFullFeatureList()

    var body: some View {
        ScrollView() {
            VStack(alignment: .leading, spacing: 8.0) {
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
                        .padding(.bottom)
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Performance plan only")
                    }
                    .font(.footnote)
                    .foregroundColor(.withColorStudio(name: .wooCommercePurple, shade: .shade50))
                    .padding(.bottom)
                    .renderedIf(featureList.performanceFeatures.isNotEmpty)
                }
                // Outside of the loop
                VStack {
                    Text(Localization.disclaimer1)
                        .font(.caption)
                    Text(Localization.disclaimer2)
                        .font(.caption)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Full Feature List")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
        })
    }
}

private extension FullFeatureListView {
    struct Localization {
        static let disclaimer1 = NSLocalizedString(
            "1. Available as standard in WooCommerce Payments (restrictions apply)." +
            "Additional extensions may be required for other payment providers." ,
            comment: "")
        static let disclaimer2 = NSLocalizedString(
            "2. Only available in the U.S. – an additional extension will be required for other countries.",
            comment: "")
    }
}
