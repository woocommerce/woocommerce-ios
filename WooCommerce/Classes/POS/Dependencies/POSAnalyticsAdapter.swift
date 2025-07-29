import Foundation
import WooFoundation

/// Adapter that implements POSAnalyticsProviding using ServiceLocator
final class POSAnalyticsAdapter: POSAnalyticsProviding {
    func track(event: WooAnalyticsEvent) {
        let mainAppEvent = WooAnalyticsEvent(statName: event.statName, properties: event.properties, error: event.error)
        ServiceLocator.analytics.track(event: mainAppEvent)
    }

    func track(_ stat: WooAnalyticsStat) {
        track(stat, parameters: [:])
    }

    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType] = [:]) {
        ServiceLocator.analytics.track(stat, withProperties: parameters)
    }

    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType] = [:], error: Error) {
        ServiceLocator.analytics.track(stat, properties: parameters, error: error)
    }
}
