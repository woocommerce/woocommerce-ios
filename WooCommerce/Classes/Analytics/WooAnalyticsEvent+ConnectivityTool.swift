import Foundation

extension WooAnalyticsEvent {
    enum ConnectivityTool {

        /// Types of connectivity tests
        ///
        enum Test: String {
            case internet
            case wpCom
            case site
            case orders
        }

        static func automaticTimeoutRetry() -> WooAnalyticsEvent {
            .init(statName: .ordersListAutomaticTimeoutRetry, properties: [:])
        }

        static func topBannerTroubleshootTapped() -> WooAnalyticsEvent {
            .init(statName: .ordersListTopBannerTroubleshootTapped, properties: [:])
        }

        static func requestResponse(test: Test, success: Bool, timeTaken: Double) -> WooAnalyticsEvent {
            .init(statName: .connectivityToolRequestResponse,
                  properties: [
                    "test": test.rawValue,
                    "success": success,
                    "time_taken": timeTaken
                  ]
            )
        }

        static func readMoreTapped() -> WooAnalyticsEvent {
            .init(statName: .connectivityToolReadMoreTapped, properties: [:])
        }

        static func contactSupportTapped() -> WooAnalyticsEvent {
            .init(statName: .connectivityToolContactSupportTapped, properties: [:])
        }
    }
}
