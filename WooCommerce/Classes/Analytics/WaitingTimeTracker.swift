import Foundation
import Combine
import protocol WooFoundation.Analytics

/// Tracks the waiting time for a given scenario, allowing to evaluate as analytics
/// how much time in seconds it took between the init and `end` function call
///
class WaitingTimeTracker {
    private let trackScenario: WooAnalyticsEvent.WaitingTime.Scenario
    private let currentTimestampSeconds: () -> TimeInterval
    private let analyticsService: Analytics
    private let waitingStartedTimestamp: TimeInterval

    enum TrackingUnit {
        case seconds
        case milliseconds
    }

    init(trackScenario: WooAnalyticsEvent.WaitingTime.Scenario,
         analyticsService: Analytics = ServiceLocator.analytics,
         currentTimestampSeconds: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.trackScenario = trackScenario
        self.analyticsService = analyticsService
        self.currentTimestampSeconds = currentTimestampSeconds
        waitingStartedTimestamp = currentTimestampSeconds()
    }

    /// Default `end()` method to preserve interface compatibility. By default, tracks in `.seconds`
    ///
    func end() {
        end(using: .seconds)
    }

    /// End the waiting time by evaluating the elapsed time from the init,
    /// and sending it as an analytics event.
    ///
    /// - Parameter trackingUnit: Defines whether the elapsed time should be tracked in `.seconds` or `.milliseconds` (default is `.seconds`).
    ///
    func end(using trackingUnit: TrackingUnit = .seconds) {
        let elapsedTime = calculateElapsedTime(in: trackingUnit)
        let analyticsEvent = WooAnalyticsEvent.WaitingTime.waitingFinished(scenario: trackScenario, elapsedTime: elapsedTime)
        analyticsService.track(event: analyticsEvent)
    }

    /// Calculates elapsed time in the specified tracking unit.
    ///
    private func calculateElapsedTime(in trackingUnit: TrackingUnit) -> TimeInterval {
        let elapsedTime = currentTimestampSeconds() - waitingStartedTimestamp
        return trackingUnit == .milliseconds ? elapsedTime * 1000 : elapsedTime
    }
}
