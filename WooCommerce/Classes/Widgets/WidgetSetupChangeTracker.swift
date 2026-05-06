import Foundation
import protocol WooFoundation.Analytics

final class WidgetSetupChangeTracker {
    private var persistence: WidgetSnapshotPersisting

    init(persistence: WidgetSnapshotPersisting = UserDefaultsWidgetSnapshotPersistence()) {
        self.persistence = persistence
    }

    func track(currentSnapshot: WidgetSnapshot, analytics: Analytics) {
        guard let previous = persistence.lastSnapshot else {
            persistence.lastSnapshot = currentSnapshot
            return
        }
        let diff = WidgetSnapshotDiff(previous: previous, current: currentSnapshot)
        guard diff.hasChanged else {
            return
        }
        analytics.track(event: WooAnalyticsEvent.Widgets.setupChanged(diff: diff))
        persistence.lastSnapshot = currentSnapshot
    }
}
