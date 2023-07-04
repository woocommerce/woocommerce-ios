import SwiftUI
import Yosemite

struct OwnerUpgradesView: View {
    @State var upgradePlan: WooWPComPlan
    @State var isPurchasing: Bool
    let purchasePlanAction: () -> Void
    @State var isLoading: Bool

    init(upgradePlan: WooWPComPlan,
         isPurchasing: Bool = false,
         purchasePlanAction: @escaping (() -> Void),
         isLoading: Bool = false) {
        _upgradePlan = .init(initialValue: upgradePlan)
        _isPurchasing = .init(initialValue: isPurchasing)
        self.purchasePlanAction = purchasePlanAction
        _isLoading = .init(initialValue: isLoading)
    }

    @State private var paymentFrequency: WooPlan.PlanFrequency = .year
    private var paymentFrequencies: [WooPlan.PlanFrequency] = [.year, .month]

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
                Section {
                    Image(upgradePlan.wooPlan.headerImageFileName)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowInsets(.zero)
                        .listRowBackground(upgradePlan.wooPlan.headerImageCardColor)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading) {
                        Text(upgradePlan.wooPlan.shortName)
                            .font(.largeTitle)
                            .accessibilityAddTraits(.isHeader)
                        Text(upgradePlan.wooPlan.planDescription)
                            .font(.subheadline)
                    }

                    VStack(alignment: .leading) {
                        Text(upgradePlan.wpComPlan.displayPrice)
                            .font(.largeTitle)
                            .accessibilityAddTraits(.isHeader)
                        Text(upgradePlan.wooPlan.planFrequency.localizedString)
                            .font(.footnote)
                    }
                }
                .accessibilityAddTraits(.isSummaryElement)
                .listRowSeparator(.hidden)

                if upgradePlan.hardcodedPlanDataIsValid {
                    Section {
                        ForEach(upgradePlan.wooPlan.planFeatureGroups, id: \.title) { featureGroup in
                            NavigationLink(destination: WooPlanFeatureBenefitsView(wooPlanFeatureGroup: featureGroup)) {
                                WooPlanFeatureGroupRow(featureGroup: featureGroup)
                            }
                            .disabled(isLoading)
                        }
                    } header: {
                        Text(String.localizedStringWithFormat(Localization.featuresHeaderTextFormat, upgradePlan.wooPlan.shortName))
                    }
                    .headerProminence(.increased)
                } else {
                    NavigationLink(destination: {
                        /// Note that this is a fallback only, and we should remove it once we load feature details remotely.
                        AuthenticatedWebView(isPresented: .constant(true),
                                             url: WooConstants.URLs.fallbackWooExpressHome.asURL())
                    }, label: {
                        Text(Localization.featureDetailsUnavailableText)
                    })
                    .disabled(isLoading)
                }
            }
            .listStyle(.insetGrouped)
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmering(active: isLoading)
            VStack {
                let buttonText = String.localizedStringWithFormat(Localization.purchaseCTAButtonText, upgradePlan.wpComPlan.displayName)
                Button(buttonText) {
                    purchasePlanAction()
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isPurchasing))
                .disabled(isLoading)
                .redacted(reason: isLoading ? .placeholder : [])
                .shimmering(active: isLoading)
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
