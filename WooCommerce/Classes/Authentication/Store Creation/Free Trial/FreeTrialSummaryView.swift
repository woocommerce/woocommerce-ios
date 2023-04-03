import SwiftUI

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
        .init(title: "Premium themes", icon: .starOutlineImage()),
        .init(title: "Unlimited products", icon: .productImage),
        .init(title: "Shipping labels", icon: .shippingOutlineIcon),
        .init(title: "Ecommerce reports", icon: .ecommerceIcon),
        .init(title: "Multiple payment options", icon: .getPaidImage),
        .init(title: "Subscriptions & product kits", icon: .giftIcon),
        .init(title: "Social advertising", icon: .megaphoneIcon),
        .init(title: "Email marketing", icon: .emailOutlineIcon),
        .init(title: "24/7 support", icon: .supportIcon),
        .init(title: "Auto updates & backups", icon: .backupsIcon),
        .init(title: "Site security", icon: .cloudOutlineImage),
        .init(title: "Fast to launch", icon: .customizeDomainsImage)
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
                    } // TODO: Align it to the left

                    Text("Launch in days,\ngrow for years")
                        .bold()
                        .titleStyle()
                        .padding(.bottom, 16)

                    Text("We offer everything you need to build and grow an online store, powered by WooCommerce and hosted on WordPress.com.")
                        .secondaryBodyStyle()
                        .padding(.trailing, 8)
                        .padding(.bottom, 32)

                    Text("Try it free for 14 days.")
                        .bold()
                        .secondaryTitleStyle()
                        .padding(.bottom, 16)

                    ForEach(Self.features, id: \.title) { feature in
                        HStack {
                            Image(uiImage: feature.icon)
                                .foregroundColor(Color(uiColor: .accent))

                            Text(feature.title)
                                .foregroundColor(Color(.text))
                                .calloutStyle()
                        }
                        .padding(.bottom, 18)
                    }

                    // WPCom logo
                    HStack {
                        Text("Powered by")
                            .foregroundColor(Color(uiColor: .textSubtle))
                            .captionStyle()

                        Image(uiImage: .wpcomLogoImage(tintColor: .textSubtle))

                    }
                }
                .padding()
            }

            // Continue Footer
            VStack() {
                Divider()

                Button {
                    print("Continue Pressed")
                } label: {
                    Text("Try For Free")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding()

                Text("No credit card required.")
                    .subheadlineStyle()
                    .scenePadding(.bottom)
            }
            .background(Color(.listForeground(modal: false)))
        }
    }
}


struct FreeTrialSummaryView_Preview: PreviewProvider {
    static var previews: some View {
        FreeTrialSummaryView()
    }
}
