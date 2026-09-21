import EventHorizonSDK
import ParcelFittingCheck
import protocol WooFoundation.Analytics

struct ParcelFittingAnalyticsAdaptor: ParcelFittingAnalyticsTracking {
    private let analytics: Analytics

    init(analytics: Analytics = ServiceLocator.analytics) {
        self.analytics = analytics
    }

    func track(_ event: Event) {
        analytics.track(event)
    }
}
