import UIKit

/// Contains all UI content to show on Dashboard
///
protocol DashboardUI: UIViewController {
    /// Called when the Dashboard should display syncing error
    var displaySyncingError: () -> Void { get set }

    /// Called when the user pulls to refresh
    var onPullToRefresh: @MainActor () async -> Void { get set }

    /// Reloads data in Dashboard
    ///
    /// - Parameter forced: pass `true` to override sync throttling
    @MainActor
    func reloadData(forced: Bool) async
}
