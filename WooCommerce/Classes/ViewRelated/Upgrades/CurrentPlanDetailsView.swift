import SwiftUI

struct CurrentPlanDetailsView: View {
    @State var expirationDate: String?
    @State var daysLeft: Int?

    private var daysLeftText: String {
        guard let daysLeft else {
            return ""
        }
        return String.pluralize(daysLeft,
                                singular: Localization.daysLeftValueSingular,
                                plural: Localization.daysLeftValuePlural)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.contentSpacing) {
            if let expirationDate = expirationDate {
                Text(Localization.freeTrialTitle)
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(String.localizedStringWithFormat(Localization.freeTrialText, daysLeftText, expirationDate))
                    .font(.footnote)
            } else {
                Text(Localization.freeTrialHasEndedTitle)
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(Localization.freeTrialExpiredText)
                    .font(.footnote)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.leading, .trailing])
        .padding(.vertical, Layout.smallPadding)
    }
}

private extension CurrentPlanDetailsView {
    struct Layout {
        static let contentSpacing: CGFloat = 8
        static let smallPadding: CGFloat = 8
    }

    enum Localization {
        static let freeTrialTitle = NSLocalizedString(
            "You're in a free trial",
            comment: "Title for the Upgrades summary card, informing the merchant they're on a Free Trial site.")

        static let freeTrialHasEndedTitle = NSLocalizedString(
            "Your free trial has ended",
            comment: "Title for the Upgrades summary card, informing the merchant their Free Trial has ended.")

        static let freeTrialText = NSLocalizedString(
            "Your free trial will end in %@. Upgrade to a plan by %@ to unlock new features and start selling.",
            comment: "Text within the Upgrades summary card, informing the merchant of how much time they have to upgrade.")

        static let freeTrialExpiredText = NSLocalizedString(
            "Don't lose all that hard work! Upgrade to a paid plan to continue working on your store. " +
            "Unlock more features, launch and start selling, and make your ecommerce business a reality.",
            comment: "Text within the Upgrades summary card, informing the merchant their Free Trial has expired.")

        static let daysLeftValuePlural = NSLocalizedString(
            "%1ld days", comment: "Value describing the days left on a plan before expiry (plural). " +
            "%1ld must be included in the translation, and will be replaced with the count. Reads as '15 days'")

        static let daysLeftValueSingular = NSLocalizedString(
            "%1$ld day", comment: "Value describing the days left on a plan before expiry (singular). " +
            "%1ld must be included in the translation, and will be replaced with the count. Reads as '1 day'")
    }
}
