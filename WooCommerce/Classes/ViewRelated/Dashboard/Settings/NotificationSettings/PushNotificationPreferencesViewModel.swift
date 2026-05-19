import Foundation
import Observation
import Yosemite

/// View model backing `PushNotificationPreferencesView`.
///
/// Loads the per-site push notification preferences served by the Woo-driven
/// push system (`wc-push-notifications/preferences`) and dispatches partial
/// updates back through Yosemite when toggles are flipped.
///
@MainActor
@Observable
final class PushNotificationPreferencesViewModel {

    enum LoadState: Equatable {
        case loading
        case loaded
        case error
    }

    private(set) var loadState: LoadState = .loading

    private(set) var isStoreOrderEnabled: Bool = false
    private(set) var isStoreReviewEnabled: Bool = false
    private(set) var isStoreStockEnabled: Bool = false

    var errorNotice: Notice?

    private let siteID: Int64
    private let stores: StoresManager
    private var preferences: PushNotificationPreferences?

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    func load() async {
        loadState = .loading
        do {
            let preferences = try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(NotificationAction.loadPushNotificationPreferences(siteID: siteID) { result in
                    continuation.resume(with: result)
                })
            }
            apply(preferences: preferences)
            loadState = .loaded
        } catch {
            DDLogError("⛔️ Error loading push notification preferences for siteID=\(siteID): \(error)")
            loadState = .error
        }
    }

    // Optimistic-update setters. If two flips of the same toggle race, only the latest revert
    // can run — the earlier closure no-ops because the toggle has since changed. Out-of-order
    // server responses can still produce a stale final state; acceptable for a 3-row screen
    // where rapid double-flips are not a real user flow.
    func setStoreOrderEnabled(_ newValue: Bool) {
        let previous = isStoreOrderEnabled
        isStoreOrderEnabled = newValue
        // `StoreOrder` is sent as a complete object (`minAmount: nil` serializes as JSON
        // `null`, which the server interprets as "clear threshold"). Preserve the loaded
        // threshold so toggling the master switch doesn't wipe it.
        let changes = PushNotificationPreferences(
            storeOrder: .init(enabled: newValue, minAmount: preferences?.storeOrder?.minAmount)
        )
        update(changes: changes, revert: { [weak self] in
            guard let self, self.isStoreOrderEnabled == newValue else { return }
            self.isStoreOrderEnabled = previous
        })
    }

    func setStoreReviewEnabled(_ newValue: Bool) {
        let previous = isStoreReviewEnabled
        isStoreReviewEnabled = newValue
        let changes = PushNotificationPreferences(storeReview: .init(enabled: newValue))
        update(changes: changes, revert: { [weak self] in
            guard let self, self.isStoreReviewEnabled == newValue else { return }
            self.isStoreReviewEnabled = previous
        })
    }

    func setStoreStockEnabled(_ newValue: Bool) {
        let previous = isStoreStockEnabled
        isStoreStockEnabled = newValue
        let changes = PushNotificationPreferences(storeStock: .init(enabled: newValue))
        update(changes: changes, revert: { [weak self] in
            guard let self, self.isStoreStockEnabled == newValue else { return }
            self.isStoreStockEnabled = previous
        })
    }
}

private extension PushNotificationPreferencesViewModel {

    func update(changes: PushNotificationPreferences, revert: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            do {
                let preferences = try await withCheckedThrowingContinuation { continuation in
                    stores.dispatch(NotificationAction.updatePushNotificationPreferences(siteID: siteID,
                                                                                         changes: changes) { result in
                        continuation.resume(with: result)
                    })
                }
                // Apply only the fields we explicitly updated. Concurrent in-flight requests for
                // other toggles must keep their optimistic state; an earlier response's view of
                // those fields is stale by definition.
                apply(preferences: preferences, fields: changes)
            } catch {
                DDLogError("⛔️ Error updating push notification preferences: \(error)")
                revert()
                errorNotice = Notice(title: Localization.errorNoticeTitle,
                                     message: Localization.errorNoticeMessage,
                                     feedbackType: .error)
            }
        }
    }

    func apply(preferences: PushNotificationPreferences) {
        self.preferences = preferences
        isStoreOrderEnabled = preferences.storeOrder?.enabled ?? false
        isStoreReviewEnabled = preferences.storeReview?.enabled ?? false
        isStoreStockEnabled = preferences.storeStock?.enabled ?? false
    }

    func apply(preferences: PushNotificationPreferences, fields: PushNotificationPreferences) {
        self.preferences = preferences
        if fields.storeOrder != nil {
            isStoreOrderEnabled = preferences.storeOrder?.enabled ?? false
        }
        if fields.storeReview != nil {
            isStoreReviewEnabled = preferences.storeReview?.enabled ?? false
        }
        if fields.storeStock != nil {
            isStoreStockEnabled = preferences.storeStock?.enabled ?? false
        }
    }
}

extension PushNotificationPreferencesViewModel {
    enum Localization {
        static let errorNoticeTitle = NSLocalizedString(
            "pushNotificationPreferencesViewModel.errorNoticeTitle",
            value: "Couldn't update notification preferences",
            comment: "Title of the notice shown when updating push notification preferences fails."
        )
        static let errorNoticeMessage = NSLocalizedString(
            "pushNotificationPreferencesViewModel.errorNoticeMessage",
            value: "Please try again.",
            comment: "Message of the notice shown when updating push notification preferences fails."
        )
    }
}
