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
            Text(Localization.freeTrialTitle)
                .font(.title2.bold())
            if let expirationDate = expirationDate {
                Text(String.localizedStringWithFormat(Localization.freeTrialText, daysLeftText, expirationDate))
                    .font(.footnote)
            } else {
                Text(Localization.freeTrialAlternativeText)
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
            comment: "Title for the Upgrade's summary card, informing the merchant they're on a Free Trial site.")

        static let freeTrialText = NSLocalizedString(
            "Your free trial will end in %@. Upgrade to a plan by %@ to unlock new features and start selling.",
            comment: "Text within the Upgrade's summary card, informing the merchant of how much time they have to upgrade.")

        static let freeTrialAlternativeText = NSLocalizedString(
            "Your free trial will end soon. Upgrade to unlock new features and start selling.",
            comment: "Text within the Upgrade's summary card, informing the merchant of how much time they have to upgrade.")

        static let daysLeftLabel = NSLocalizedString(
             "Days left in plan", comment: "Label for the text describing days left on a Plan to expire." +
             "Reads as 'Days left in plan: 15 days left'")

        static let daysLeftValuePlural = NSLocalizedString(
            "%1ld days", comment: "Value describing the days left on a plan before expiry (plural). " +
            "%1ld must be included in the translation, and will be replaced with the count. Reads as '15 days'")

        static let daysLeftValueSingular = NSLocalizedString(
                    "%1$ld day", comment: "Value describing the days left on a plan before expiry (singular). " +
                    "%1ld must be included in the translation, and will be replaced with the count. Reads as '1 day'")
    }
}
