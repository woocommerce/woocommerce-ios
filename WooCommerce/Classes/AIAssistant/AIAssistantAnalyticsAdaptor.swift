import Foundation
import protocol WooFoundation.Analytics
import protocol WooAIAssistant.AssistantAnalyticsProviding

struct AIAssistantAnalyticsAdaptor: @unchecked Sendable, AssistantAnalyticsProviding {

    private let analytics: Analytics

    init(analytics: Analytics) {
        self.analytics = analytics
    }

    func track(event: String, properties: [String: String]) {
        let convertedProperties: [AnyHashable: Any]? = properties.isEmpty ? nil : properties
        analytics.track(event, properties: convertedProperties, error: nil)
    }
}
