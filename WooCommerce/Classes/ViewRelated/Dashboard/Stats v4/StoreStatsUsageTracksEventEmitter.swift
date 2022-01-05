import Foundation

/// Note: If we ever change the algorithm in the future, we should probably consider renaming
/// the Tracks event to avoid incorrect comparisons with old events.
final class StoreStatsUsageTracksEventEmitter {

    private let analytics: Analytics

    /// The minimum amount of time (seconds) that the merchant have interacted with the
    /// Analytics UI before an event is triggered.
    private let minimumInteractionTime: TimeInterval = 10

    /// The minimum number of Analytics UI interactions before an event is triggered.
    ///
    /// The interactions captured are:
    ///
    /// - Scrolling
    /// - Pull-to-refresh
    /// - Tapping on the bars in the chart
    /// - Changing the tab
    /// - Navigating to the My Store tab
    /// - Tapping on a product in the Top Performers list
    private let interactionsThreshold = 5

    /// The maximum number of seconds in between interactions before we will consider the
    /// merchant to have been idle. If they were idle, the time and interactions counting
    /// will be reset.
    private let idleTimeThreshold: TimeInterval = 20

    private var interactions = 0
    private var firstInteractionTime: Date? = nil
    private var lastInteractionTime: Date? = nil

    init(analytics: Analytics = ServiceLocator.analytics) {
        self.analytics = analytics
    }

    func interacted(at interactionTime: Date = Date()) {
        // Check if they were idle for some time.
        if let lastInteractionTime = lastInteractionTime,
           interactionTime.timeIntervalSince(lastInteractionTime) >= idleTimeThreshold {
            reset()
        }

        guard let firstInteractionTime = firstInteractionTime else {
            interactions = 1
            self.firstInteractionTime = interactionTime
            self.lastInteractionTime = interactionTime

            return
        }

        interactions += 1
        lastInteractionTime = interactionTime

        if interactionTime.timeIntervalSince(firstInteractionTime) >= minimumInteractionTime &&
            interactions >= interactionsThreshold {

            reset()
            analytics.track(.usedAnalytics)
        }
    }

    private func reset() {
        interactions = 0
        firstInteractionTime = nil
        lastInteractionTime = nil
    }
}
