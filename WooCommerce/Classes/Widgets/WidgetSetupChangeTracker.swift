import Foundation

final class WidgetSetupChangeTracker {
    private var persistence: WidgetSnapshotPersisting

    init(persistence: WidgetSnapshotPersisting = UserDefaultsWidgetSnapshotPersistence()) {
        self.persistence = persistence
    }

    /// Compares the current snapshot against the persisted baseline. Returns the diff to merge
    /// into the next `application_opened` payload, or `nil` if there is no baseline yet (first
    /// observation) or no change since the last one. Persists the new baseline as a side effect
    /// when a change is detected.
    func evaluate(currentSnapshot: WidgetSnapshot) -> WidgetSnapshotDiff? {
        guard let previous = persistence.lastSnapshot else {
            persistence.lastSnapshot = currentSnapshot
            return nil
        }
        let diff = WidgetSnapshotDiff(previous: previous, current: currentSnapshot)
        guard diff.hasChanged else {
            return nil
        }
        persistence.lastSnapshot = currentSnapshot
        return diff
    }
}
