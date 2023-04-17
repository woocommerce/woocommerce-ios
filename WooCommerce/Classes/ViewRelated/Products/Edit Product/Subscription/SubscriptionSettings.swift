import SwiftUI

// MARK: Hosting Controller

/// Hosting controller that wraps a `SubscriptionSettings` view.
///
final class SubscriptionSettingsViewController: UIHostingController<SubscriptionSettings> {
    init() {
        super.init(rootView: SubscriptionSettings())
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Views

/// Renders the subscription settings for a subscription product.
///
struct SubscriptionSettings: View {

    /// Environment safe areas
    ///
    @Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                TitleAndSubtitleRow(title: "Subscription price", subtitle: "$60.00 every 4 months")
                Divider()
                    .padding(.leading)
                    .padding(.trailing, insets: -safeAreaInsets)

                TitleAndSubtitleRow(title: "Expire after", subtitle: "12 months")
                Divider()
                    .padding(.leading)
                    .padding(.trailing, insets: -safeAreaInsets)

                TitleAndSubtitleRow(title: "Signup fee", subtitle: "$5.00")
                Divider()
                    .padding(.leading)
                    .padding(.trailing, insets: -safeAreaInsets)

                TitleAndSubtitleRow(title: "Free trial", subtitle: "No trial period")
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .addingTopAndBottomDividers()
            .background(Color(.listForeground(modal: false)))

            FooterNotice(infoText: "You can edit subscription settings in the web dashboard")
                .padding(.horizontal, insets: safeAreaInsets)
        }
        .ignoresSafeArea(edges: .horizontal)
        .background(
            Color(.listBackground).edgesIgnoringSafeArea(.all)
        )
    }
}

struct SubscriptionSettings_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionSettings()
    }
}
