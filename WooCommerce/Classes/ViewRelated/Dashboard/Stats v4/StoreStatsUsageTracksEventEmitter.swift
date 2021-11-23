import Foundation

/// Note: If we ever change the algorithm in the future, we should probably consider renaming
/// the Tracks event to avoid incorrect comparisons with old events.
final class StoreStatsUsageTracksEventEmitter {

    /// TODO Replace with proper injection
    static let shared = StoreStatsUsageTracksEventEmitter()

    private let analytics: Analytics

    private let minimumInteractionTime: TimeInterval = 10
    private let interactionsThreshold = 5
    private let idleTimeThreshold: TimeInterval = 10

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

            // TODO Remove :D
            let notice = Notice(title: "You used Analytics! Good for you!", feedbackType: .success)
            ServiceLocator.noticePresenter.enqueue(notice: notice)
        }
    }

    private func reset() {
        interactions = 0
        firstInteractionTime = nil
        lastInteractionTime = nil
    }
}
