import SwiftUI
import Yosemite
import WooFoundation

struct OwnerUpgradesView: View {

    @State var upgradePlans: [WooWPComPlan]
    @Binding var isPurchasing: Bool
    @Binding var expirationDate: String?
    @Binding var planDaysLeft: Int?
    let purchasePlanAction: (WooWPComPlan) -> Void
    @State var isLoading: Bool

    init(upgradePlans: [WooWPComPlan],
         isPurchasing: Binding<Bool>,
         expirationDate: Binding<String?>,
         planDaysLeft: Binding<Int?>,
         purchasePlanAction: @escaping ((WooWPComPlan) -> Void),
         isLoading: Bool = false) {
        _upgradePlans = .init(initialValue: upgradePlans)
        _isPurchasing = isPurchasing
        _expirationDate = expirationDate
        _planDaysLeft = planDaysLeft
        self.purchasePlanAction = purchasePlanAction
        _isLoading = .init(initialValue: isLoading)
    }

    @State private var paymentFrequency: WooPlan.PlanFrequency = .month
    private var paymentFrequencies: [WooPlan.PlanFrequency] = [.month, .year]

    @State var selectedPlan: WooWPComPlan? = nil
    @State private var showingFullFeatureList = false

    var body: some View {
        VStack(spacing: 0) {
            VStack {
                CurrentPlanDetailsView(expirationDate: expirationDate,
                                       daysLeft: planDaysLeft)
                .background(Color(.secondarySystemGroupedBackground))
            }
            .padding(.horizontal)
            .cornerRadius(Layout.cornerRadius)
            .background(Color(.systemGroupedBackground))
            .redacted(reason: isLoading ? .placeholder : [])

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

            ScrollView {
                VStack {
                    ForEach(upgradePlans.filter { $0.wooPlan.planFrequency == paymentFrequency }) { upgradePlan in
                        WooPlanCardView(upgradePlan: upgradePlan, selectedPlan: $selectedPlan)
                            .disabled(isPurchasing)
                            .listRowSeparator(.hidden)
                            .redacted(reason: isLoading ? .placeholder : [])
                            .padding(.bottom, 8)
                    }
                    Button(Localization.allFeaturesListText) {
                        showingFullFeatureList.toggle()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(isPurchasing || isLoading)
                    .redacted(reason: isLoading ? .placeholder : [])
                    .sheet(isPresented: $showingFullFeatureList) {
                        NavigationView {
                            FullFeatureListView()
                        }
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
                } else {
                    Button(Localization.selectPlanButtonText) {
                        // no-op
                    }
                    .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isPurchasing))
                    .disabled(true)
                    .redacted(reason: isLoading ? .placeholder : [])
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

private extension OwnerUpgradesView {
    enum Layout {
        static let cornerRadius: CGFloat = 8.0
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

        static let allFeaturesListText = NSLocalizedString(
            "View Full Feature List",
            comment: "The title of the button to view a list of all features that plans offer.")
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
