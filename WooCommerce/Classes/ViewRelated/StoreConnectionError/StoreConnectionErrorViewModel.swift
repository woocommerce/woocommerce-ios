import Combine
import Foundation
import UIKit
import Yosemite

/// Decides when to tell the merchant that the selected store can't be reached.
///
/// The store is flagged by the networking layer when it rejects our requests with Jetpack's invalid
/// signature error, and unflagged as soon as it answers normally again. On top of that this view model
/// applies two rules: the warning only concerns the store the merchant is currently looking at, and
/// tapping Dismiss silences it for the rest of the session only, so a store that is still unreachable
/// the next time the app comes to the foreground says so again.
///
@MainActor
final class StoreConnectionErrorViewModel: ObservableObject {
    @Published private(set) var isPresented = false

    private let monitor: StoreConnectionErrorMonitoring
    private let isSnoozed = CurrentValueSubject<Bool, Never>(false)
    private var subscriptions: Set<AnyCancellable> = []

    init(monitor: StoreConnectionErrorMonitoring = StoreConnectionErrorMonitor.shared,
         stores: StoresManager = ServiceLocator.stores,
         notificationCenter: NotificationCenter = .default) {
        self.monitor = monitor

        monitor.affectedSiteIDPublisher
            .combineLatest(stores.siteID, isSnoozed)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] affectedSiteID, selectedSiteID, isSnoozed in
                guard let self else {
                    return
                }
                let isAffected = affectedSiteID != nil && affectedSiteID == selectedSiteID
                self.isPresented = isAffected && !isSnoozed

                // Once the store recovers, or the merchant moves to another one, the snooze has served
                // its purpose: drop it so the next occurrence is surfaced right away. Guarded on the
                // current value because this subject feeds the combine above, and re-sending the same
                // value would loop.
                if !isAffected, self.isSnoozed.value {
                    self.isSnoozed.send(false)
                }
            }
            .store(in: &subscriptions)

        notificationCenter.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, isSnoozed.value else {
                    return
                }
                isSnoozed.send(false)
            }
            .store(in: &subscriptions)
    }

    /// Silences the warning until the app is next brought to the foreground.
    ///
    func dismissTapped() {
        isSnoozed.send(true)
    }
}
