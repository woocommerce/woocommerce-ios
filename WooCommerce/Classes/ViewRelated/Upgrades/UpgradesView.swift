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

    private var planText: String {
        String.localizedStringWithFormat(Localization.planName, subscriptionsViewModel.planName)
    }

    private var daysLeftText: String {
        String.localizedStringWithFormat(Localization.daysLeftInTrial, subscriptionsViewModel.planDaysLeft)
    }

    init(upgradesViewModel: UpgradesViewModel, subscriptionsViewModel: SubscriptionsViewModel) {
        self.upgradesViewModel = upgradesViewModel
        self.subscriptionsViewModel = subscriptionsViewModel
    }

    var body: some View {
        VStack {
            CurrentPlanDetailsView(planText: planText, daysLeftText: daysLeftText)

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
        VStack {
            Spacer()

            Image(uiImage: .emptyOrdersImage)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack {
                if let availableProduct = upgradesViewModel.retrievePlanDetailsIfAvailable(.essentialMonthly) {
                    Text(availableProduct.displayName)
                        .font(.title)
                    Text(Localization.upgradeSubtitle)
                        .font(.body)
                    Text(availableProduct.displayPrice)
                        .font(.title)
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
    @State var planText: String
    @State var daysLeftText: String

    var body: some View {
        VStack(alignment: .leading, spacing: UpgradesView.Layout.contentSpacing) {
            Text(planText)
            Text(daysLeftText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading)
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
        if let wpcomPlan = upgradesViewModel.retrievePlanDetailsIfAvailable(.essentialMonthly) {
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

private extension OwnerUpgradesView {
    struct Localization {
        static let purchaseCTAButtonText = NSLocalizedString("Purchase %1$@", comment: "The title of the button to purchase a Plan." +
                                                             "Reads as 'Purchase Essential Monthly'")
        static let upgradeSubtitle = NSLocalizedString("Everything you need to launch an online store",
                                                       comment: "Subtitle that can be read under the Plan upgrade name")
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

        static let planName = NSLocalizedString("Your Plan: %1$@", comment: "Message describing which Plan the merchant is currently subscribed to." +
                                                "Reads as 'Your Plan: Free Trial'")
        static let daysLeftInTrial = NSLocalizedString("Days left in trial: %1$@", comment: "Message describing days left on a Plan to expire." +
                                                       "Reads as 'Days left in trial: 15'")
    }

    struct Layout {
        static let contentSpacing: CGFloat = 8
    }
}
