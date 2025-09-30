import Foundation

/// Tracks the waiting time for a given scenario, allowing to evaluate as analytics
/// how much time in seconds it took between the init and `end` function call
///
public class WaitingTimeTracker {
    private let trackScenario: WooAnalyticsEvent.WaitingTime.Scenario
    private let currentTimestampSeconds: () -> TimeInterval
    private let waitingStartedTimestamp: TimeInterval

    public enum TrackingUnit {
        case seconds
        case milliseconds
    }

    public init(trackScenario: WooAnalyticsEvent.WaitingTime.Scenario,
                currentTimestampSeconds: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.trackScenario = trackScenario
        self.currentTimestampSeconds = currentTimestampSeconds
        waitingStartedTimestamp = currentTimestampSeconds()
    }

    /// Default `end()` method to preserve interface compatibility. By default, tracks in `.seconds`
    /// - Returns: The analytics event to be tracked.
    ///
    public func end() -> WooAnalyticsEvent {
        end(using: .seconds)
    }

    /// End the waiting time by evaluating the elapsed time from the init,
    /// and returning an analytics event for tracking.
    ///
    /// - Parameter trackingUnit: Defines whether the elapsed time should be tracked in `.seconds` or `.milliseconds` (default is `.seconds`).
    /// - Returns: The analytics event to be tracked.
    ///
    public func end(using trackingUnit: TrackingUnit = .seconds) -> WooAnalyticsEvent {
        let elapsedTime = calculateElapsedTime(in: trackingUnit)
        return .WaitingTime.waitingFinished(scenario: trackScenario, elapsedTime: elapsedTime)
    }

    /// Calculates elapsed time in the specified tracking unit.
    ///
    private func calculateElapsedTime(in trackingUnit: TrackingUnit) -> TimeInterval {
        let elapsedTime = currentTimestampSeconds() - waitingStartedTimestamp
        return trackingUnit == .milliseconds ? elapsedTime * 1000 : elapsedTime
    }
}

// MARK: - Waiting Time measurement
//
public extension WooAnalyticsEvent {
    enum WaitingTime {
        /// Possible Waiting time scenarios
        public enum Scenario {
            case orderDetails
            case dashboardTopPerformers
            case dashboardMainStats
            case analyticsHub
            case appStartup
            case pointOfSaleLoaded
        }

        private enum Keys {
            static let waitingTime = "waiting_time"
            static let millisecondsTimeElapsedInSplashScreen = "milliseconds_time_elapsed_in_splash_screen"
        }

        static func waitingFinished(scenario: Scenario, elapsedTime: TimeInterval) -> WooAnalyticsEvent {
            switch scenario {
            case .orderDetails:
                return WooAnalyticsEvent(statName: .orderDetailWaitingTimeLoaded, properties: [Keys.waitingTime: elapsedTime])
            case .dashboardTopPerformers:
                return WooAnalyticsEvent(statName: .dashboardTopPerformersWaitingTimeLoaded, properties: [Keys.waitingTime: elapsedTime])
            case .dashboardMainStats:
                return WooAnalyticsEvent(statName: .dashboardMainStatsWaitingTimeLoaded, properties: [Keys.waitingTime: elapsedTime])
            case .analyticsHub:
                return WooAnalyticsEvent(statName: .analyticsHubWaitingTimeLoaded, properties: [Keys.waitingTime: elapsedTime])
            case .appStartup:
                return WooAnalyticsEvent(statName: .applicationOpenedWaitingTimeLoaded, properties: [Keys.waitingTime: elapsedTime])
            case .pointOfSaleLoaded:
                return WooAnalyticsEvent(statName: .pointOfSaleLoaded, properties: [Keys.millisecondsTimeElapsedInSplashScreen: elapsedTime])
            }
        }
    }
}
