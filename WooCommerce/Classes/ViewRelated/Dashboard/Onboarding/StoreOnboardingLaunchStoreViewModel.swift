import SwiftUI
import Yosemite

/// View model for `StoreOnboardingLaunchStoreView`.
final class StoreOnboardingLaunchStoreViewModel: ObservableObject {
    let siteURL: URL

    @Published private(set) var isLaunchingStore: Bool = false
    @Published var error: SiteLaunchError?
    @Published private(set) var canPublishStore: Bool = false

    private let siteID: Int64
    private let stores: StoresManager
    private let onLaunch: () -> Void

    /// Closure invoked when the merchants taps on the `Upgrade` button.
    ///
    private let onUpgradeTapped: () -> Void

    init(siteURL: URL,
         siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         onLaunch: @escaping () -> Void,
         onUpgradeTapped: @escaping () -> Void) {
        self.siteURL = siteURL
        self.siteID = siteID
        self.stores = stores
        self.onLaunch = onLaunch
        self.onUpgradeTapped = onUpgradeTapped
    }

    @MainActor
    func checkEligibilityToPublishStore() async {
        canPublishStore = !(await isFreeTrialPlan())
    }

    @MainActor
    func launchStore() async {
        error = nil
        isLaunchingStore = true
        let result = await launchStoreRemotely()
        switch result {
        case .success:
            onLaunch()
        case .failure(let error):
            self.error = error
        }
        isLaunchingStore = false
    }

    @MainActor
    func didTapUpgrade() {
        onUpgradeTapped()
    }
}

private extension StoreOnboardingLaunchStoreViewModel {
    @MainActor
    func isFreeTrialPlan() async -> Bool {
        // Only fetch free trial information if the site is a WPCom site.
        guard stores.sessionManager.defaultSite?.isWordPressComStore == true else {
            return false
        }

        return await withCheckedContinuation({ continuation in
            let action = PaymentAction.loadSiteCurrentPlan(siteID: siteID) { result in
                switch result {
                case .success(let plan):
                    return continuation.resume(returning: plan.isFreeTrial)
                case .failure(let error):
                    DDLogError("⛔️ Error fetching the current site's plan information: \(error)")
                    return continuation.resume(returning: false)
                }
            }
            stores.dispatch(action)
        })
    }

    @MainActor
    func launchStoreRemotely() async -> Result<Void, SiteLaunchError> {
        await withCheckedContinuation { continuation in
            stores.dispatch(SiteAction.launchSite(siteID: siteID) { result in
                continuation.resume(returning: result)
            })
        }
    }
}
