import SwiftUI

/// View to inform the benefits of a free trial
///
struct FreeTrialSummaryView: View {

    static let features: [String] = [
        "Premium themes",
        "Unlimited products",
        "Shipping labels",
        "Ecommerce reports",
        "Multiple payment options",
        "Subscriptions & product kits",
        "Social advertising",
        "Email marketing",
        "24/7 support",
        "Auto updates & backups",
        "Site security",
        "Fast to launch"
    ]


    var body: some View {
        VStack(spacing: .zero) {
            // Main Content
            ScrollView {
                VStack(alignment: .leading) {

                    /// Align image to the right
                    HStack {
                        Spacer()
                        Image(uiImage: .freeTrialIllustration)
                    }

                    Text("Launch in days, grow for years")
                        .titleStyle()

                    Text("We offer everything you need to build and grow an online store, powered by WooCommerce and hosted on WordPress.com.")
                        .calloutStyle()

                    Text("Try it free for 14 days.")
                        .secondaryTitleStyle()

                    ForEach(Self.features, id: \.self) { feature in
                        HStack {
                            Rectangle()
                                .frame(width: 16, height: 16)

                            Text(feature)
                        }
                    }

                    // TODO: Add WordPress Indicator
                }
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
                    .calloutStyle()
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
