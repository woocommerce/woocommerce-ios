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

    @State var isPurchasing = false

    private var planText: String {
        String.localizedStringWithFormat(Localization.planName, subscriptionsViewModel.planName)
    }

    private var daysLeftText: String {
        String.localizedStringWithFormat(Localization.daysLeftInTrial, subscriptionsViewModel.planDaysLeft)
    }

    private var siteName: String? {
        ServiceLocator.stores.sessionManager.defaultSite?.name
    }

    init(upgradesViewModel: UpgradesViewModel, subscriptionsViewModel: SubscriptionsViewModel) {
        self.upgradesViewModel = upgradesViewModel
        self.subscriptionsViewModel = subscriptionsViewModel
    }

    var body: some View {
        List {
            Section {
                Text(planText)
                Text(daysLeftText)
            }
            Section {
                Image(uiImage: upgradesViewModel.userIsAdministrator ? .emptyOrdersImage : .noStoreImage)
            }
            Section {
                VStack(alignment: .center, spacing: Layout.contentSpacing) {
                    Text(Localization.unableToUpgradeText)
                    if let siteName = siteName {
                        Text(siteName)
                    }
                    Text(Localization.unableToUpgradeInstructions)
                }
            }
            .renderedIf(!upgradesViewModel.userIsAdministrator)
            Section {
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
            }
            .renderedIf(upgradesViewModel.userIsAdministrator)
            Section {
                if upgradesViewModel.wpcomPlans.isEmpty || isPurchasing {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                } else {
                    ForEach(upgradesViewModel.wpcomPlans, id: \.id) { wpcomPlan in
                        let buttonText = String.localizedStringWithFormat(Localization.purchaseCTAButtonText, wpcomPlan.displayName)
                        Button(buttonText) {
                            // TODO: Add product entitlement check
                            Task {
                                isPurchasing = true
                                await upgradesViewModel.purchasePlan(with: wpcomPlan.id)
                                isPurchasing = false
                            }
                        }
                    }
                }
            }
            .renderedIf(upgradesViewModel.userIsAdministrator)
        }
        .task {
            if upgradesViewModel.userIsAdministrator {
                await upgradesViewModel.fetchPlans()
            }
        }
        .navigationBarTitle(Localization.navigationTitle)
        .padding(.top)
    }
}

private extension UpgradesView {
    struct Localization {
        static let navigationTitle = NSLocalizedString("Plans", comment: "Navigation title for the Upgrades screen")
        static let purchaseCTAButtonText = NSLocalizedString("Purchase %1$@", comment: "The title of the button to purchase a Plan." +
                                                             "Reads as 'Purchase Essential Monthly'")
        static let planName = NSLocalizedString("Your Plan: %1$@", comment: "Message describing which Plan the merchant is currently subscribed to." +
                                                "Reads as 'Your Plan: Free Trial'")
        static let daysLeftInTrial = NSLocalizedString("Days left in trial: %1$@", comment: "Message describing days left on a Plan to expire." +
                                                       "Reads as 'Days left in trial: 15'")
        static let upgradeSubtitle = NSLocalizedString("Everything you need to launch an online store",
                                                       comment: "Subtitle that can be read under the Plan upgrade name")
        static let unableToUpgradeText = NSLocalizedString("Unable to upgrade", comment: "")
        static let unableToUpgradeInstructions = NSLocalizedString("Only the site owner can manage upgrades. " +
                                                    "Please contact the site owner.", comment: "")
        static let goBackButtonTitle = NSLocalizedString("Go back", comment: "")
    }
    enum Layout {
        static let contentSpacing: CGFloat = 8
    }
}
