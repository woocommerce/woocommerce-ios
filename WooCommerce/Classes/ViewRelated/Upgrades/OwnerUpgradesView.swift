import SwiftUI
import Yosemite
import WooFoundation

struct OwnerUpgradesView: View {
    @State var upgradePlans: [WooWPComPlan]
    @State var isPurchasing: Bool
    let purchasePlanAction: (WooWPComPlan) -> Void
    @State var isLoading: Bool

    init(upgradePlans: [WooWPComPlan],
         isPurchasing: Bool = false,
         purchasePlanAction: @escaping ((WooWPComPlan) -> Void),
         isLoading: Bool = false) {
        _upgradePlans = .init(initialValue: upgradePlans)
        _isPurchasing = .init(initialValue: isPurchasing)
        self.purchasePlanAction = purchasePlanAction
        _isLoading = .init(initialValue: isLoading)
    }

    @State private var paymentFrequency: WooPlan.PlanFrequency = .year
    private var paymentFrequencies: [WooPlan.PlanFrequency] = [.year, .month]

    @State var selectedPlan: WooWPComPlan? = nil

    var body: some View {
        VStack(spacing: 0) {
            Picker(selection: $paymentFrequency, label: EmptyView()) {
                ForEach(paymentFrequencies) {
                    Text($0.paymentFrequencyLocalizedString)
                }
            }
            .pickerStyle(.segmented)
            .disabled(isLoading)
            .padding()
            .background(Color(.systemGroupedBackground))
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmering(active: isLoading)

            ScrollView {
                VStack {
                    ForEach(upgradePlans.filter { $0.wooPlan.planFrequency == paymentFrequency }) { upgradePlan in
                        WooPlanCardView(upgradePlan: upgradePlan, selectedPlan: $selectedPlan)
                        .accessibilityAddTraits(.isSummaryElement)
                        .listRowSeparator(.hidden)
                        .redacted(reason: isLoading ? .placeholder : [])
                        .shimmering(active: isLoading)
                        .padding(.bottom, 8)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))

            VStack {
                if let selectedPlan {
                    let buttonText = String.localizedStringWithFormat(Localization.purchaseCTAButtonText, selectedPlan.wpComPlan.displayName)
                    Button(buttonText) {
                        purchasePlanAction(selectedPlan)
                    }
                    .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isPurchasing))
                    .disabled(isLoading)
                    .redacted(reason: isLoading ? .placeholder : [])
                    .shimmering(active: isLoading)
                } else {
                    Button(Localization.selectPlanButtonText) {
                        // no-op
                    }
                    .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isPurchasing))
                    .disabled(true)
                    .redacted(reason: isLoading ? .placeholder : [])
                    .shimmering(active: isLoading)
                }
            }
            .padding()
        }
    }
}

private struct WooPlanCardView: View {
    let upgradePlan: WooWPComPlan
    @Binding var selectedPlan: WooWPComPlan?

    private var isSelected: Bool {
        selectedPlan?.id == upgradePlan.id
    }

    private var isPopular: Bool {
        let popularPlans =  [
            AvailableInAppPurchasesWPComPlans.performanceMonthly.rawValue,
            AvailableInAppPurchasesWPComPlans.performanceYearly.rawValue
        ]

        return popularPlans.contains(where: {$0 == upgradePlan.id})
    }
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            VStack(alignment: .leading, spacing: Layout.spacing) {
                HStack {
                    Text(upgradePlan.wooPlan.shortName)
                        .font(.title)
                        .bold()
                        .accessibilityAddTraits(.isHeader)

                    Spacer()

                    BadgeView(text: Localization.isPopularBadgeText.uppercased()).renderedIf(isPopular)
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? Color.withColorStudio(name: .wooCommercePurple, shade: .shade50) : Color(.systemGray4))
                        .font(.system(size: Layout.checkImageSize))

                }
                Text(upgradePlan.wooPlan.planDescription)
                    .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: Layout.textSpacing) {
                Text(upgradePlan.wpComPlan.displayPrice)
                    .font(.largeTitle)
                    .accessibilityAddTraits(.isHeader)
                Text(upgradePlan.wooPlan.planFrequency.localizedString)
                    .font(.footnote)
            }

            let buttonText = String.localizedStringWithFormat(Localization.viewPlanFeaturesFormat, upgradePlan.wooPlan.shortName)
            Button("\(buttonText) \(Image(systemName: isExpanded ? "chevron.up" : "chevron.down"))") {
                isExpanded.toggle()
            }
            Text("Expanded").renderedIf(isExpanded)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
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

private extension OwnerUpgradesView {
    struct Localization {
        static let purchaseCTAButtonText = NSLocalizedString(
            "Purchase %1$@",
            comment: "The title of the button to purchase a Plan." +
            "Reads as 'Purchase Essential Monthly'")

        static let featuresHeaderTextFormat = NSLocalizedString(
            "Get the most out of %1$@",
            comment: "Title for the section header for the list of feature categories on the Upgrade plan screen. " +
            "Reads as 'Get the most out of Essential'. %1$@ must be included in the string and will be replaced with " +
            "the plan name.")

        static let featureDetailsUnavailableText = NSLocalizedString(
            "See plan details", comment: "Title for a link to view Woo Express plan details on the web, as a fallback.")

        static let selectPlanButtonText = NSLocalizedString(
            "Select a plan", comment: "The title of the button to purchase a Plan when no plan is selected yet.")
    }
}

private extension WooPlan.PlanFrequency {
    var paymentFrequencyLocalizedString: String {
        switch self {
        case .month:
            return Localization.payMonthly
        case .year:
            return Localization.payAnnually
        }
    }

    enum Localization {
        static let payMonthly = NSLocalizedString(
            "Monthly",
            comment: "Title of the selector option for paying monthly on the Upgrade view, when choosing a plan")

        static let payAnnually = NSLocalizedString(
            "Annually (Save 35%)",
            comment: "Title of the selector option for paying annually on the Upgrade view, when choosing a plan")
    }
}
