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

    @State private var showingUpgradesNotAllowedSheetView = false
    @State var isPurchasing = false

    private var planText: String {
        String.localizedStringWithFormat(Constants.planName, subscriptionsViewModel.planName)
    }
    private var daysLeftText: String {
        String.localizedStringWithFormat(Constants.daysLeftInTrial, subscriptionsViewModel.planDaysLeft)
    }

    init(upgradesViewModel: UpgradesViewModel, subscriptionsViewModel: SubscriptionsViewModel) {
        self.upgradesViewModel = upgradesViewModel
        self.subscriptionsViewModel = subscriptionsViewModel
        self.showingUpgradesNotAllowedSheetView = false
    }

    var body: some View {
        List {
            Section {
                Text(planText)
                Text(daysLeftText)
            }
            Section {
                VStack {
                    Image(uiImage: .emptyOrdersImage)
                    if let availableProduct = upgradesViewModel.retrievePlanDetailsIfAvailable(.essentialMonthly) {
                        Text(availableProduct.displayName)
                            .font(.title)
                        Text(Constants.upgradeSubtitle)
                            .font(.body)
                        Text(availableProduct.displayPrice)
                            .font(.title)
                    }
                }
            }
            Section {
                if upgradesViewModel.wpcomPlans.isEmpty || isPurchasing {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                } else {
                    ForEach(upgradesViewModel.wpcomPlans, id: \.id) { wpcomPlan in
                        let buttonText = String.localizedStringWithFormat(Constants.purchaseCTAButtonText, wpcomPlan.displayName)
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
        }
        .task {
            if upgradesViewModel.userIsAdministrator {
                await upgradesViewModel.fetchPlans()
            } else {
                showingUpgradesNotAllowedSheetView = true
            }
        }
        .navigationBarTitle(Constants.navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: $showingUpgradesNotAllowedSheetView) {
            UpgradesNotAllowedSheetView()
        }
    }
}

struct UpgradesNotAllowedSheetView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .center, spacing: Layout.contentSpacing) {
            Image(uiImage: .noStoreImage)
            Text(Localization.title)
                .secondaryTitleStyle()
                .multilineTextAlignment(.center)
            Text(Localization.siteName)
                .frame(maxWidth: .infinity)
                .headlineStyle()
                .background(Color(.systemGray6))
            Text(Localization.instructions)
                .subheadlineStyle()
                .multilineTextAlignment(.center)
        }
        .padding(Layout.contentSpacing)
        .safeAreaInset(edge: .bottom) {
            VStack {
                Divider()
                    .dividerStyle()
                Button(Localization.goBackButtonTitle) {
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(Layout.contentSpacing)
            }
            .background(Color(.systemBackground))
        }
        .navigationBarBackButtonHidden()
    }
}

private extension UpgradesNotAllowedSheetView {
    enum Localization {
        static let title = NSLocalizedString("Unable to upgrade", comment: "")
        static let siteName = NSLocalizedString("mysiteaddress.com", comment: "")
        static let instructions = NSLocalizedString("Only the site owner can manage upgrades. " +
                                                    "Please contact the site owner.", comment: "")
        static let goBackButtonTitle = NSLocalizedString("Go back", comment: "")
    }
    enum Layout {
        static let contentSpacing: CGFloat = 24
    }
}

private extension UpgradesView {
    struct Constants {
        static let navigationTitle = NSLocalizedString("Plans", comment: "Navigation title for the Upgrades screen")
        static let purchaseCTAButtonText = NSLocalizedString("Purchase %1$@", comment: "The title of the button to purchase a Plan." +
                                                             "Reads as 'Purchase Essential Monthly'")
        static let planName = NSLocalizedString("Your Plan: %1$@", comment: "Message describing which Plan the merchant is currently subscribed to." +
                                                "Reads as 'Your Plan: Free Trial'")
        static let daysLeftInTrial = NSLocalizedString("Days left in trial: %1$@", comment: "Message describing days left on a Plan to expire." +
                                                       "Reads as 'Days left in trial: 15'")
        static let upgradeSubtitle = NSLocalizedString("Everything you need to launch an online store",
                                                       comment: "Subtitle that can be read under the Plan upgrade name")
    }
}
