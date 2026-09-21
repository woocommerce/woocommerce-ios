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
            case products
            case analytics
            case notifications
        }

        static func automaticTimeoutRetry() -> WooAnalyticsEvent {
            .init(statName: .ordersListAutomaticTimeoutRetry, properties: [:])
        }

        static func topBannerTroubleshootTapped() -> WooAnalyticsEvent {
            .init(statName: .ordersListTopBannerTroubleshootTapped, properties: [:])
        }

        static func settingsTroubleshootTapped() -> WooAnalyticsEvent {
            .init(statName: .settingsTroubleshootConnectionTapped, properties: [:])
        }

        /// `skipped` is true when the site cannot answer the test; `success` is then true as no failure was found.
        static func requestResponse(test: Test, success: Bool, timeTaken: Double, skipped: Bool = false) -> WooAnalyticsEvent {
            .init(statName: .connectivityToolRequestResponse,
                  properties: [
                    "test": test.rawValue,
                    "success": success,
                    "time_taken": timeTaken,
                    "skipped": skipped
                  ]
            )
        }

        static func readMoreTapped() -> WooAnalyticsEvent {
            .init(statName: .connectivityToolReadMoreTapped, properties: [:])
        }

        static func preLoginRequestResponse(testName: String, success: Bool, timeTaken: Double) -> WooAnalyticsEvent {
            .init(statName: .preLoginConnectivityToolRequestResponse,
                  properties: [
                    "test": testName,
                    "success": success,
                    "time_taken": timeTaken
                  ]
            )
        }
    }
}
