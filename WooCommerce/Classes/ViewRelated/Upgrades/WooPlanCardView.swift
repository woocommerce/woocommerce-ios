import Yosemite
import SwiftUI

struct WooPlanCardView: View {
    let upgradePlan: WooWPComPlan
    @Binding var selectedPlan: WooWPComPlan?

    private var isSelected: Bool {
        selectedPlan?.id == upgradePlan.id
    }

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            VStack(alignment: .leading, spacing: Layout.spacing) {
                HStack {
                    Text(upgradePlan.wooPlan.shortName)
                        .font(.title2)
                        .bold()

                    Spacer()

                    BadgeView(text: Localization.isPopularBadgeText.uppercased())
                        .renderedIf(upgradePlan.shouldDisplayIsPopularBadge)
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? Color.withColorStudio(name: .wooCommercePurple, shade: .shade50) : Color(.systemGray4))
                        .font(.system(size: Layout.checkImageSize))
                }
                .accessibilityElement()
                .accessibilityLabel(upgradePlan.wooPlan.shortName)
                .accessibilityAddTraits([.isHeader, .isButton])
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])

                Text(upgradePlan.wooPlan.planDescription)
                    .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: Layout.textSpacing) {
                Text(upgradePlan.wpComPlan.displayPrice)
                    .font(.title)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                Text(upgradePlan.wooPlan.planFrequency.localizedString)
                    .font(.footnote)
            }

            let buttonText = String.localizedStringWithFormat(Localization.viewPlanFeaturesFormat, upgradePlan.wooPlan.shortName)
            Button("\(buttonText) \(Image(systemName: isExpanded ? "chevron.up" : "chevron.down"))") {
                isExpanded.toggle()
            }
            WooPlanCardFeaturesView(upgradePlan).renderedIf(isExpanded)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.vertical)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(isSelected ? .withColorStudio(name: .wooCommercePurple, shade: .shade50) : Color(.systemGray4),
                        lineWidth: isSelected ? Layout.selectedBorder : Layout.unselectedBorder)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if selectedPlan?.id != upgradePlan.id {
                selectedPlan = upgradePlan
            }
        }
    }
}

private struct WooPlanCardFeaturesView: View {
    private let plan: WooWPComPlan

    init(_ plan: WooWPComPlan) {
        self.plan = plan
    }

    var planFeatures: [String] {
        plan.wooPlan.planFeatures
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.featureTextSpacing) {
            Text(Localization.upsellFeatureTitleText)
                .bold()
                .font(.footnote)
                .renderedIf(!plan.wooPlan.isEssential)
            ForEach(planFeatures, id: \.self) { feature in
                Text(feature)
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
            }
            Text(Localization.storageText.uppercased())
                .bold()
                .font(.footnote)
            BadgeView(text: Localization.storageAmountText, customizations: .init(textColor: Color(.text), backgroundColor: Color(.systemGray4)))
                .font(.footnote)
        }
    }
}

private extension WooPlanCardFeaturesView {
    enum Localization {
        static let upsellFeatureTitleText = NSLocalizedString("Everything in Essential, plus:",
                                                              comment: "Title for the Performance plan features list." +
                                                              " Is followed by a list of the plan features.")

        static let storageText = NSLocalizedString("Storage",
                                                   comment: "Title of one of the features of the Paid plans, regarding site storage.")

        static let storageAmountText = NSLocalizedString("50 GB",
                                                         comment: "Content of one of the features of the Paid plans, pointing to gigabytes of site storage.")
    }

    enum Layout {
        static let featureTextSpacing: CGFloat = 8.0
    }
}

private extension WooPlanCardView {
    enum Layout {
        static let cornerRadius: CGFloat = 8.0
        static let selectedBorder: CGFloat = 2
        static let unselectedBorder: CGFloat = 0.5
        static let checkImageSize: CGFloat = 24
        static let spacing: CGFloat = 16
        static let textSpacing: CGFloat = 4
    }

    enum Localization {
        static let viewPlanFeaturesFormat = NSLocalizedString(
            "View %1$@ features",
            comment: "Title for the button to expand plan details on the Upgrade plan screen. " +
            "Reads as 'View Essential features'. %1$@ must be included in the string and will be replaced with " +
            "the plan name.")

        static let isPopularBadgeText = NSLocalizedString(
            "Popular",
            comment: "The text of the badge that indicates the most popular choice when purchasing a Plan")
    }
}
