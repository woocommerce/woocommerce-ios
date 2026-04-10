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
    /// - Parameter additionalProperties: Optional additional properties to include in the analytics event.
    /// - Returns: The analytics event to be tracked.
    ///
    public func end(using trackingUnit: TrackingUnit = .seconds, additionalProperties: [String: String] = [:]) -> WooAnalyticsEvent {
        let elapsedTime = calculateElapsedTime(in: trackingUnit)
        return .WaitingTime.waitingFinished(scenario: trackScenario, elapsedTime: elapsedTime, additionalProperties: additionalProperties)
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

        static func waitingFinished(scenario: Scenario,
                                     elapsedTime: TimeInterval,
                                     additionalProperties: [String: String] = [:]) -> WooAnalyticsEvent {
            // Convert additional properties to WooAnalyticsEventPropertyType
            let typedAdditionalProperties: [String: WooAnalyticsEventPropertyType] =
                additionalProperties.mapValues { $0 as WooAnalyticsEventPropertyType }

            let statName: WooAnalyticsStat
            var baseProperties: [String: WooAnalyticsEventPropertyType]

            switch scenario {
            case .orderDetails:
                statName = .orderDetailWaitingTimeLoaded
                baseProperties = [Keys.waitingTime: elapsedTime]
            case .dashboardTopPerformers:
                statName = .dashboardTopPerformersWaitingTimeLoaded
                baseProperties = [Keys.waitingTime: elapsedTime]
            case .dashboardMainStats:
                statName = .dashboardMainStatsWaitingTimeLoaded
                baseProperties = [Keys.waitingTime: elapsedTime]
            case .analyticsHub:
                statName = .analyticsHubWaitingTimeLoaded
                baseProperties = [Keys.waitingTime: elapsedTime]
            case .appStartup:
                statName = .applicationOpenedWaitingTimeLoaded
                baseProperties = [Keys.waitingTime: elapsedTime]
            case .pointOfSaleLoaded:
                statName = .pointOfSaleLoaded
                baseProperties = [Keys.millisecondsTimeElapsedInSplashScreen: elapsedTime]
            }

            return WooAnalyticsEvent(
                statName: statName,
                properties: baseProperties.merging(typedAdditionalProperties) { $1 })
        }
    }
}
