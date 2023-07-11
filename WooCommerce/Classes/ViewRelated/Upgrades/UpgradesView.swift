import Foundation
import SwiftUI
import Yosemite
import Experiments

final class UpgradesViewPresentationCoordinator {
    private let featureFlagService: FeatureFlagService
    private let inAppPurchaseManager: InAppPurchasesForWPComPlansProtocol

    init(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         inAppPurchaseManager: InAppPurchasesForWPComPlansProtocol = InAppPurchasesForWPComPlansManager()) {
        self.featureFlagService = featureFlagService
        self.inAppPurchaseManager = inAppPurchaseManager
    }

    func presentUpgrades(for siteID: Int64, from viewController: UIViewController) {
        Task { @MainActor in
            if await inAppPurchaseManager.inAppPurchasesAreSupported() {
                if featureFlagService.isFeatureFlagEnabled(.freeTrialInAppPurchasesUpgradeM2) {
                    let upgradesController = UpgradesHostingController(siteID: siteID)
                    viewController.present(upgradesController, animated: true)
                } else {
                    let legacyUpgradesController = LegacyUpgradesHostingController(siteID: siteID)
                    viewController.present(legacyUpgradesController, animated: true)
                }
            } else {
                let subscriptionsController = SubscriptionsHostingController(siteID: siteID)
                viewController.present(subscriptionsController, animated: true)
            }
        }
    }
}

/// Hosting controller for `UpgradesView`
/// To be used to display available current plan Subscriptions, available plan Upgrades,
/// and the CTA to upgrade
///
final class UpgradesHostingController: UIHostingController<UpgradesView> {
    private let authentication: Authentication = ServiceLocator.authenticationManager

    init(siteID: Int64) {
        let upgradesViewModel = UpgradesViewModel(siteID: siteID)
        let subscriptionsViewModel = SubscriptionsViewModel()

        super.init(rootView: UpgradesView(upgradesViewModel: upgradesViewModel, subscriptionsViewModel: subscriptionsViewModel))

        rootView.supportHandler = { [weak self] in
            self?.openSupport()
        }
    }

    func openSupport() {
        authentication.presentSupport(from: self, screen: .purchasePlanError)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}

struct UpgradesView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var upgradesViewModel: UpgradesViewModel
    @ObservedObject var subscriptionsViewModel: SubscriptionsViewModel

    var supportHandler: () -> Void = {}

    init(upgradesViewModel: UpgradesViewModel,
         subscriptionsViewModel: SubscriptionsViewModel) {
        self.upgradesViewModel = upgradesViewModel
        self.subscriptionsViewModel = subscriptionsViewModel
    }

    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    // TODO: Once we remove iOS 15 support, we can do this with .toolbar instead.
                    UpgradeTopBarView(dismiss: {
                        dismiss()
                    })

                    CurrentPlanDetailsView(planName: subscriptionsViewModel.planName,
                                           daysLeft: subscriptionsViewModel.planDaysLeft)
                }
                .renderedIf(upgradesViewModel.upgradeViewState.shouldShowPlanDetailsView)

                switch upgradesViewModel.upgradeViewState {
                case .loading:
                    OwnerUpgradesView(upgradePlans: [
                        .skeletonPlan(frequency: .year, shortName: "Essential"),
                        .skeletonPlan(frequency: .year, shortName: "Performance"),
                        .skeletonPlan(frequency: .month, shortName: "Essential"),
                        .skeletonPlan(frequency: .month, shortName: "Performance")],
                                      purchasePlanAction: { _ in }, isLoading: true)
                        .accessibilityLabel(Localization.plansLoadingAccessibilityLabel)
                case .loaded(let plans):
                    OwnerUpgradesView(upgradePlans: plans, purchasePlanAction: { selectedPlan in
                        Task {
                            await upgradesViewModel.purchasePlan(with: selectedPlan.wpComPlan.id)
                        }
                    })
                case .purchasing(_, let plans):
                    OwnerUpgradesView(upgradePlans: plans, isPurchasing: true, purchasePlanAction: { _ in })
                case .waiting(let plan):
                    ScrollView(.vertical) {
                        UpgradeWaitingView(planName: plan.wooPlan.shortName)
                    }
                case .completed(let plan):
                    CompletedUpgradeView(planName: plan.wooPlan.shortName,
                                         doneAction: {
                        dismiss()
                    })
                case .prePurchaseError(let error):
                    ScrollView(.vertical) {
                        VStack {
                            PrePurchaseUpgradesErrorView(error,
                                                         onRetryButtonTapped: {
                                upgradesViewModel.retryFetch()
                            })
                            .padding(.top, Layout.errorViewTopPadding)
                            .padding(.horizontal, Layout.errorViewHorizontalPadding)

                            Spacer()
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                case .purchaseUpgradeError(.inAppPurchaseFailed(let plan, let iapStoreError)):
                    PurchaseUpgradeErrorView(error: .inAppPurchaseFailed(plan, iapStoreError)) {
                        Task {
                            await upgradesViewModel.purchasePlan(with: plan.wpComPlan.id)
                        }
                    } secondaryAction: {
                        dismiss()
                    } getSupportAction: {
                        supportHandler()
                    }
                case .purchaseUpgradeError(let underlyingError):
                    // handles .planActivationFailed and .unknown underlyingErrors
                    PurchaseUpgradeErrorView(error: underlyingError,
                                             primaryAction: nil,
                                             secondaryAction: {
                        dismiss()
                    },
                                             getSupportAction: supportHandler)
                }
            }
            .navigationBarHidden(true)
        }
        // TODO: when we remove iOS 15 support, use NavigationStack instead.
        // This is required to avoid a column layout on iPad, which looks strange.
        .navigationViewStyle(.stack)
        .onDisappear {
            upgradesViewModel.onDisappear()
        }
        .task {
            await upgradesViewModel.prepareViewModel()
        }
    }
}

private extension UpgradesView {
    struct Layout {
        static let errorViewHorizontalPadding: CGFloat = 20
        static let errorViewTopPadding: CGFloat = 36
        static let padding: CGFloat = 16
        static let contentSpacing: CGFloat = 8
        static let smallPadding: CGFloat = 8
    }

    enum Localization {
        static let plansLoadingAccessibilityLabel = NSLocalizedString(
            "Loading plan details",
            comment: "Accessibility label for the initial loading state of the Upgrades view")
    }
}

private extension WooWPComPlan {
    static func skeletonPlan(frequency: WooPlan.PlanFrequency, shortName: String) -> WooWPComPlan {
        let planProduct = SkeletonWPComPlanProduct(displayName: "\(frequency.localizedPlanName) \(shortName) Plan",
                                                   id: "skeleton.wpcom.plan.product.monthly",
                                                   price: "$100")
        return WooWPComPlan(
            wpComPlan: planProduct,
            wooPlan: WooPlan(id: "skeleton.plan.\(shortName).\(frequency.rawValue)",
                             name: "Skeleton \(shortName) Plan \(frequency.localizedPlanName)",
                             shortName: "Skeleton",
                             planFrequency: frequency,
                             planDescription: "A skeleton plan to show (redacted) while we're loading",
                             headerImageFileName: "express-essential-header",
                             headerImageCardColor: .withColorStudio(name: .orange, shade: .shade5),
                             planFeatureGroups: []),
            hardcodedPlanDataIsValid: true)
    }

    private struct SkeletonWPComPlanProduct: WPComPlanProduct {
        let displayName: String
        let description: String = "A skeleton plan to show (redacted) while we're loading"
        let id: String
        let displayPrice: String

        init(displayName: String,
             id: String,
             price: String) {
            self.displayName = displayName
            self.id = id
            self.displayPrice = price
        }


    }
}

struct UpgradesView_Preview: PreviewProvider {
    static var previews: some View {
        UpgradesView(upgradesViewModel: UpgradesViewModel(siteID: 0),
                     subscriptionsViewModel: SubscriptionsViewModel())
    }
}
