import Combine
import Foundation
import UIKit
import Yosemite

/// Decides when to tell the merchant that the selected store can't be reached.
///
/// The store is flagged by the networking layer when it rejects our requests with Jetpack's invalid
/// signature error, and unflagged as soon as it answers normally again. On top of that this view model
/// applies two rules: the warning only concerns the store the merchant is currently looking at, and
/// tapping Dismiss silences that store for the rest of the session only, so one that is still unreachable
/// the next time the app comes to the foreground says so again.
///
@MainActor
final class StoreConnectionErrorViewModel: ObservableObject {
    @Published private(set) var isPresented = false

    private let monitor: StoreConnectionErrorMonitoring

    /// The store the merchant dismissed the warning for, if any.
    ///
    /// Keyed by store rather than a plain flag so it silences that store and nothing else: a second store
    /// failing is news the merchant hasn't seen yet, and looking at a healthy store in the meantime does
    /// not use the snooze up.
    ///
    private let snoozedSiteID = CurrentValueSubject<Int64?, Never>(nil)
    private var subscriptions: Set<AnyCancellable> = []

    init(monitor: StoreConnectionErrorMonitoring = StoreConnectionErrorMonitor.shared,
         stores: StoresManager = ServiceLocator.stores,
         notificationCenter: NotificationCenter = .default) {
        self.monitor = monitor

        monitor.affectedSiteIDPublisher
            .combineLatest(stores.siteID, snoozedSiteID)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] affectedSiteID, selectedSiteID, snoozedSiteID in
                guard let self else {
                    return
                }
                let isAffected = affectedSiteID != nil && affectedSiteID == selectedSiteID
                self.isPresented = isAffected && snoozedSiteID != affectedSiteID

                // The snooze has done its job once the store it was taken for recovers, so drop it and
                // let a fresh failure speak up. Guarded on the current value because this subject feeds
                // the combine above, and re-sending the same value would loop.
                if affectedSiteID == nil, self.snoozedSiteID.value != nil {
                    self.snoozedSiteID.send(nil)
                }
            }
            .store(in: &subscriptions)

        notificationCenter.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, snoozedSiteID.value != nil else {
                    return
                }
                snoozedSiteID.send(nil)
            }
            .store(in: &subscriptions)
    }

    /// Silences the warning for the affected store until the app is next brought to the foreground.
    ///
    func dismissTapped() {
        snoozedSiteID.send(monitor.affectedSiteID)
    }
}
