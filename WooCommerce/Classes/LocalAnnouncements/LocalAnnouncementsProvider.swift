import Experiments
import Foundation
import Yosemite

/// Provides the local announcements to be displayed on the dashboard tab.
///
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

    func loadAnnouncement() async -> LocalAnnouncementViewModel? {
        guard featureFlagService.isFeatureFlagEnabled(.productDescriptionAIFromStoreOnboarding) else {
            return nil
        }
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
                return stores.sessionManager.defaultSite?.isWordPressComStore == true
        }
    }
}
