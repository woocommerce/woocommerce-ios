import Foundation
import Yosemite
import Experiments
import Combine

final class TapToPayBadgePromotionChecker {
    private let featureFlagService: FeatureFlagService
    private let stores: StoresManager

    @Published private(set) var shouldShowTapToPayBadges: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    init(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         stores: StoresManager = ServiceLocator.stores) {
        self.featureFlagService = featureFlagService
        self.stores = stores

        listenToTapToPayBadgeReloadRequired()
        Task {
            await checkTapToPayBadgeVisibility()
        }
    }

    func hideTapToPayBadge() {
        guard shouldShowTapToPayBadges else {
            return
        }
        let action = AppSettingsAction.setFeatureAnnouncementDismissed(campaign: .tapToPayHubMenuBadge, remindAfterDays: nil, onCompletion: nil)
        stores.dispatch(action)
        shouldShowTapToPayBadges = false
    }

    @MainActor
    private func checkTapToPayBadgeVisibility() async {
        guard let siteID = stores.sessionManager.defaultStoreID else {
            return shouldShowTapToPayBadges = false
        }

        let supportDeterminer = CardReaderSupportDeterminer(siteID: siteID)
        guard supportDeterminer.siteSupportsLocalMobileReader(),
              await supportDeterminer.deviceSupportsLocalMobileReader(),
              await !supportDeterminer.hasPreviousTapToPayUsage() else {
            return shouldShowTapToPayBadges = false
        }

        do {
            let visible = try await withCheckedThrowingContinuation({ [weak self] continuation in
                let action = AppSettingsAction.getFeatureAnnouncementVisibility(campaign: .tapToPayHubMenuBadge) { result in
                    continuation.resume(with: result)
                }
                self?.stores.dispatch(action)
            })
            shouldShowTapToPayBadges = visible && featureFlagService.isFeatureFlagEnabled(.tapToPayBadge)
        } catch {
            DDLogError("Could not fetch feature announcement visibility \(error)")
        }
    }

    private func listenToTapToPayBadgeReloadRequired() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(setUpTapToPayViewDidAppear),
                                               name: .setUpTapToPayViewDidAppear,
                                               object: nil)
        // It's not ideal that we need this, and the notification should be removed when we remove this badge.
        // Changing the store recreates this class, so we check for support again... however, the store country is
        // fetched by the CardPresentPaymentsConfigurationLoader, from the `ServiceLocator.selectedSiteSettings`.
        // The site settings are not updated until slightly later, so we need to refresh the badge logic when they are.
        // Ideally, we would improve the CardPresentConfigurationLoader to accurately get the current country.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshBadgeVisibility),
                                               name: .selectedSiteSettingsRefreshed,
                                               object: nil)
    }

    @objc private func setUpTapToPayViewDidAppear() {
        hideTapToPayBadge()
    }

    @objc private func refreshBadgeVisibility() {
        Task {
            await checkTapToPayBadgeVisibility()
        }
    }
}
