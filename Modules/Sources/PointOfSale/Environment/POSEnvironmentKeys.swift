import SwiftUI
import WooFoundation

/// Environment key for POS analytics service
public struct POSAnalyticsKey: EnvironmentKey {
    public static let defaultValue: POSAnalyticsProviding = DefaultPOSAnalytics()
}

/// Default implementation that does nothing (for previews/testing)
private struct DefaultPOSAnalytics: POSAnalyticsProviding {
    func track(event: WooAnalyticsEvent) {
        // No-op implementation for previews/testing
    }

    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType] = [:]) {
        // No-op implementation for previews/testing
    }

    func track(_ stat: WooAnalyticsStat) {
        // No-op implementation for previews/testing
    }

    func track(_ stat: WooFoundationCore.WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType], error: any Error) {
        // No-op implementation for previews/testing
    }
}

public extension EnvironmentValues {
    var posAnalytics: POSAnalyticsProviding {
        get { self[POSAnalyticsKey.self] }
        set { self[POSAnalyticsKey.self] = newValue }
    }
}
