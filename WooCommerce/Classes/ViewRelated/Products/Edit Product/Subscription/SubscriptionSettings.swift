import SwiftUI

// MARK: Hosting Controller

/// Hosting controller that wraps a `SubscriptionSettings` view.
///
final class SubscriptionSettingsViewController: UIHostingController<SubscriptionSettings> {
    init(viewModel: SubscriptionSettingsViewModel) {
        super.init(rootView: SubscriptionSettings(viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Views

/// Renders the subscription settings for a subscription product.
///
struct SubscriptionSettings: View {

    /// View model that directs the view content.
    ///
    let viewModel: SubscriptionSettingsViewModel

    /// Environment safe areas
    ///
    @Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                // Subscription price
                TitleAndSubtitleRow(title: Localization.priceTitle, subtitle: viewModel.priceDescription)
                Divider()
                    .padding(.leading)
                    .padding(.trailing, insets: -safeAreaInsets)

                // Expire after
                TitleAndSubtitleRow(title: Localization.expiryTitle, subtitle: viewModel.expiryDescription)
                Divider()
                    .padding(.leading)
                    .padding(.trailing, insets: -safeAreaInsets)

                // Signup fee
                TitleAndSubtitleRow(title: Localization.signupFeeTitle, subtitle: viewModel.signupFeeDescription)
                Divider()
                    .padding(.leading)
                    .padding(.trailing, insets: -safeAreaInsets)

                // Free trial
                TitleAndSubtitleRow(title: Localization.freeTrialTitle, subtitle: viewModel.freeTrialDescription)
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .addingTopAndBottomDividers()
            .background(Color(.listForeground(modal: false)))

            FooterNotice(infoText: Localization.infoNotice)
                .padding(.horizontal, insets: safeAreaInsets)
        }
        .navigationBarTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .horizontal)
        .background(
            Color(.listBackground).edgesIgnoringSafeArea(.all)
        )
    }
}

private extension SubscriptionSettings {
    enum Localization {
        static let title = NSLocalizedString("Subscription", comment: "Title for the subscription settings in a subscription product.")
        static let infoNotice = NSLocalizedString("You can edit subscription settings in the web dashboard",
                                                  comment: "Info notice at the bottom of the subscription settings screen.")
        static let priceTitle = NSLocalizedString("Subscription price",
                                                  comment: "Label for the subscription price setting in the subscription settings screen.")
        static let expiryTitle = NSLocalizedString("Expire after", comment: "Label for the expiry setting in the subscription settings screen.")
        static let signupFeeTitle = NSLocalizedString("Signup fee", comment: "Label for the signup fee setting in the subscription settings screen.")
        static let freeTrialTitle = NSLocalizedString("Free trial", comment: "Label for the free trial setting in the subscription settings screen.")
    }
}

struct SubscriptionSettings_Previews: PreviewProvider {

    static let viewModel = SubscriptionSettingsViewModel(price: "$60.00 every 4 months",
                                                         expiresAfter: "12 months",
                                                         signupFee: "$5.00",
                                                         freeTrial: "No trial period")

    static var previews: some View {
        SubscriptionSettings(viewModel: viewModel)
    }
}
