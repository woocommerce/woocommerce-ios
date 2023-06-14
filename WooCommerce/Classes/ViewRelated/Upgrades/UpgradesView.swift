import Foundation
import SwiftUI

/// Hosting controller for `UpgradesView`
/// To be used to display available current plan Subscriptions, available plan Upgrades,
/// and the CTA to upgrade
///
@MainActor
final class UpgradesHostingController: UIHostingController<UpgradesView> {
    init(siteID: Int64) {
        let upgradesViewModel = UpgradesViewModel(siteID: siteID)
        let subscriptionsViewModel = SubscriptionsViewModel()

        super.init(rootView: UpgradesView(upgradesViewModel: upgradesViewModel,
                                          subscriptionsViewModel: subscriptionsViewModel))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}

struct UpgradesView: View {
    @ObservedObject var upgradesViewModel: UpgradesViewModel
    @ObservedObject var subscriptionsViewModel: SubscriptionsViewModel

    init(upgradesViewModel: UpgradesViewModel, subscriptionsViewModel: SubscriptionsViewModel) {
        self.upgradesViewModel = upgradesViewModel
        self.subscriptionsViewModel = subscriptionsViewModel
    }

    var body: some View {
        VStack {
            CurrentPlanDetailsView(planName: subscriptionsViewModel.planName, daysLeft: subscriptionsViewModel.planDaysLeft)

            Spacer()

            if upgradesViewModel.userIsAdministrator {
                OwnerUpgradesView(upgradesViewModel: upgradesViewModel)
            } else {
                NonOwnerUpgradesView(upgradesViewModel: upgradesViewModel)
            }
        }
        .navigationBarTitle(UpgradesView.Localization.navigationTitle)
        .padding(.top)
    }
}

struct OwnerUpgradesView: View {
    @ObservedObject var upgradesViewModel: UpgradesViewModel

    @State var isPurchasing = false

    private var showingInAppPurchasesDebug: Bool {
        ServiceLocator.generalAppSettings.betaFeatureEnabled(.inAppPurchases)
    }

    var body: some View {
        List {
            if let availableProduct = upgradesViewModel.upgradePlan {
                Section {
                    Image(availableProduct.wooPlan?.headerImageFileName ?? "")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowInsets(.zero)
                        //TODO: move the background color to woo-express-essential-plan-benefits.json
                        .listRowBackground(Color(red: 238/255, green: 226/255, blue: 211/255))

                    VStack(alignment: .leading) {
                        Text(availableProduct.wooPlan?.shortName ?? availableProduct.wpComPlan.displayName)
                            .font(.largeTitle)
                        Text(availableProduct.wooPlan?.planDescription ?? "")
                            .font(.subheadline)
                    }

                    VStack(alignment: .leading) {
                        Text(availableProduct.wpComPlan.displayPrice)
                            .font(.largeTitle)
                        Text(availableProduct.wooPlan?.planFrequency.localizedString ?? "")
                            .font(.footnote)
                    }
                }
                .listRowSeparator(.hidden)

                if let wooPlan = availableProduct.wooPlan {
                    Text("Get the most out of \(wooPlan.shortName)")
                        .font(.title3.weight(.semibold))
                    Section {
                        ForEach(wooPlan.planFeatureGroups, id: \.title) { featureGroup in
                            WooPlanFeatureGroupRow(featureGroup: featureGroup)
                        }
                    }
                }
            }

            Spacer()

            VStack {
                if upgradesViewModel.wpcomPlans.isEmpty || isPurchasing {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    Spacer()
                } else if showingInAppPurchasesDebug {
                    renderAllUpgrades()
                } else {
                    renderSingleUpgrade()
                }
            }

            Spacer()
        }
        .task {
            await upgradesViewModel.fetchPlans()
        }
    }
}

struct NonOwnerUpgradesView: View {
    @ObservedObject var upgradesViewModel: UpgradesViewModel

    private var siteName: String? {
        ServiceLocator.stores.sessionManager.defaultSite?.name
    }

    var body: some View {
        VStack {
            Spacer()

            Image(uiImage: .noStoreImage)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()

            VStack(alignment: .center, spacing: UpgradesView.Layout.contentSpacing) {
                Text(Localization.unableToUpgradeText)
                    .bold()
                    .headlineStyle()
                if let siteName = siteName {
                    Text(siteName)
                }
                Text(Localization.unableToUpgradeInstructions)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

private struct CurrentPlanDetailsView: View {
    @State var planName: String
    @State var daysLeft: String

    private var daysLeftText: String {
        String.localizedStringWithFormat(Localization.daysLeftValue, daysLeft)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UpgradesView.Layout.contentSpacing) {
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
    }

    private enum Localization {
        static let yourPlanLabel = NSLocalizedString(
            "Your plan", comment: "Label for the text describing which Plan the merchant is currently subscribed to." +
            "Reads as 'Your Plan: Free Trial'")

        static let daysLeftLabel = NSLocalizedString(
            "Days left in plan", comment: "Label for the text describing days left on a Plan to expire." +
            "Reads as 'Days left in plan: 15 days left'")

        static let daysLeftValue = NSLocalizedString(
            "%1$@ days left", comment: "Value describing the days left on a plan before expiry. Reads as '15 days left'")
    }
}

struct UpgradesView_Preview: PreviewProvider {
    static var previews: some View {
        UpgradesView(upgradesViewModel: UpgradesViewModel(siteID: 0),
                     subscriptionsViewModel: SubscriptionsViewModel())
    }
}

private extension OwnerUpgradesView {
    @ViewBuilder
    func renderAllUpgrades() -> some View {
        VStack {
            ForEach(upgradesViewModel.wpcomPlans, id: \.id) { wpcomPlan in
                let buttonText = String.localizedStringWithFormat(Localization.purchaseCTAButtonText, wpcomPlan.displayName)
                Button(buttonText) {
                    Task {
                        isPurchasing = true
                        await upgradesViewModel.purchasePlan(with: wpcomPlan.id)
                        isPurchasing = false
                    }
                }
            }
        }
    }

    @ViewBuilder
    func renderSingleUpgrade() -> some View {
        if let upgradePlan = upgradesViewModel.upgradePlan {
            let buttonText = String.localizedStringWithFormat(Localization.purchaseCTAButtonText, upgradePlan.wpComPlan.displayName)
            Button(buttonText) {
                Task {
                    isPurchasing = true
                    await upgradesViewModel.purchasePlan(with: upgradePlan.wpComPlan.id)
                    isPurchasing = false
                }
            }
        }
    }
}

private extension OwnerUpgradesView {
    struct Localization {
        static let purchaseCTAButtonText = NSLocalizedString("Purchase %1$@", comment: "The title of the button to purchase a Plan." +
                                                             "Reads as 'Purchase Essential Monthly'")
    }
}

private extension NonOwnerUpgradesView {
    struct Localization {
        static let unableToUpgradeText = NSLocalizedString("Unable to upgrade",
                                                           comment: "Text describing that is not possible to upgrade the site's plan.")
        static let unableToUpgradeInstructions = NSLocalizedString("Only the site owner can manage upgrades",
                                                                   comment: "Text describing that only the site owner can upgrade the site's plan.")
    }
}

private extension UpgradesView {
    struct Localization {
        static let navigationTitle = NSLocalizedString("Plans", comment: "Navigation title for the Upgrades screen")
    }

    struct Layout {
        static let contentSpacing: CGFloat = 8
    }
}
