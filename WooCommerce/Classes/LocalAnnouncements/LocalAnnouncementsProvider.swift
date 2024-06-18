import Experiments
import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// Provides the local announcements to be displayed on the dashboard tab.
///
@MainActor
final class LocalAnnouncementsProvider {
    private let stores: StoresManager
    private let analytics: Analytics
    private let featureFlagService: FeatureFlagService
    // The order of the announcements is based on the priority.
    private let announcements: [LocalAnnouncement] = [.productDescriptionAI]

    init(stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.stores = stores
        self.analytics = analytics
        self.featureFlagService = featureFlagService
    }

    /// Loops through the list of announcements in the order of priority from high to low, and returns the first announcement that
    /// is eligible and hasn't been dismissed before.
    /// - Returns: An announcement to be displayed, if it's eligible and hasn't been dismissed before. `nil` is returned if there
    ///            is no announcement to be displayed.
    func loadAnnouncement() async -> LocalAnnouncementViewModel? {
        for announcement in announcements {
            guard isEligible(announcement: announcement), await isVisible(announcement: announcement) else {
                continue
            }
            return .init(announcement: announcement, stores: stores, analytics: analytics)
        }
        return nil
    }
}

private extension LocalAnnouncementsProvider {
    @MainActor
    func isVisible(announcement: LocalAnnouncement) async -> Bool {
        await withCheckedContinuation { continuation in
            stores.dispatch(AppSettingsAction.getLocalAnnouncementVisibility(announcement: announcement) { isVisible in
                continuation.resume(returning: isVisible)
            })
        }
    }

    func isEligible(announcement: LocalAnnouncement) -> Bool {
        switch announcement {
            case .productDescriptionAI:
                guard featureFlagService.isFeatureFlagEnabled(.productDescriptionAIFromStoreOnboarding) else {
                    return false
                }
                return stores.sessionManager.defaultSite?.isWordPressComStore == true
        }
    }
}
