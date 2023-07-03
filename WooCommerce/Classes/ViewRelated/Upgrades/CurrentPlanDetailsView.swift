import SwiftUI

struct CurrentPlanDetailsView: View {
    @State var planName: String
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
            HStack {
                Text(Localization.yourPlanLabel)
                    .font(.footnote)
                Spacer()
                Text(planName)
                    .font(.footnote.bold())
            }
            HStack {
                Text(Localization.daysLeftLabel)
                    .font(.footnote)
                Spacer()
                Text(daysLeftText)
                    .font(.footnote.bold())
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
        static let yourPlanLabel = NSLocalizedString(
            "Your plan", comment: "Label for the text describing which Plan the merchant is currently subscribed to." +
            "Reads as 'Your Plan: Free Trial'")

        static let daysLeftLabel = NSLocalizedString(
            "Days left in plan", comment: "Label for the text describing days left on a Plan to expire." +
            "Reads as 'Days left in plan: 15 days left'")

        static let daysLeftValuePlural = NSLocalizedString(
            "%1ld days left", comment: "Value describing the days left on a plan before expiry (plural). " +
            "%1ld must be included in the translation, and will be replaced with the count. Reads as '15 days left'")

        static let daysLeftValueSingular = NSLocalizedString(
            "%1$ld day left", comment: "Value describing the days left on a plan before expiry (singular). " +
            "%1ld must be included in the translation, and will be replaced with the count. Reads as '1 day left'")
    }
}
