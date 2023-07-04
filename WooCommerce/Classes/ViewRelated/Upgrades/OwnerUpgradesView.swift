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
            Section {
                Picker("How frequently would you like to pay?", selection: $paymentFrequency) {
                    ForEach(paymentFrequencies) {
                        Text($0.paymentFrequencyLocalizedString)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(isLoading)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmering(active: isLoading)
            List {
                ForEach(upgradePlans.filter { $0.wooPlan.planFrequency == paymentFrequency }) { upgradePlan in
                    Section {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(upgradePlan.wooPlan.shortName)
                                    .font(.largeTitle)
                                    .accessibilityAddTraits(.isHeader)

                                Spacer()

                                if selectedPlan?.id == upgradePlan.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.withColorStudio(name: .wooCommercePurple, shade: .shade50))
                                        .font(.system(size: 30))
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(Color(.systemGray4))
                                        .font(.system(size: 30))
                                }

                            }
                            Text(upgradePlan.wooPlan.planDescription)
                                .font(.subheadline)
                        }
                        .padding(.top)

                        VStack(alignment: .leading) {
                            Text(upgradePlan.wpComPlan.displayPrice)
                                .font(.largeTitle)
                                .accessibilityAddTraits(.isHeader)
                            Text(upgradePlan.wooPlan.planFrequency.localizedString)
                                .font(.footnote)
                        }
                        .padding(.bottom)
                    }
                    .accessibilityAddTraits(.isSummaryElement)
                    .listRowSeparator(.hidden)
                    .gesture(TapGesture()
                        .onEnded({ _ in
                            if selectedPlan?.id != upgradePlan.id {
                                selectedPlan = upgradePlan
                            }
                        }))
                }
            }
            .listStyle(.insetGrouped)
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmering(active: isLoading)
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
                    Button("Choose a plan") {
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
            "Pay Monthly",
            comment: "Title of the selector option for paying monthly on the Upgrade view, when choosing a plan")

        static let payAnnually = NSLocalizedString(
            "Pay Annually",
            comment: "Title of the selector option for paying annually on the Upgrade view, when choosing a plan")
    }
}
