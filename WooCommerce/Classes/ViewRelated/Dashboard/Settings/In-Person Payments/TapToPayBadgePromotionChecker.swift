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
//        Task { @MainActor in
//            await checkTapToPayBadgeVisibility()
//        }
        stores.siteID.sink { [checkTapToPayBadgeVisibility] siteID in
            Task {
                await checkTapToPayBadgeVisibility(siteID)
            }
        }.store(in: &cancellables)
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
    private func checkTapToPayBadgeVisibility(siteID: Int64?) async {
        guard let siteID else {
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

    }

    @objc private func setUpTapToPayViewDidAppear() {
        hideTapToPayBadge()
    }
}
