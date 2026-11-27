import struct WooFoundation.WooAnalyticsEvent

extension WooAnalyticsEvent {
    enum POSOnboardingGuide {
        private enum Key {
            static let step = "step"
        }

        static func shown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleOnboardingShown, properties: [:])
        }

        static func stepViewed(step: POSOnboardingGuideStep) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleOnboardingStepViewed, properties: [Key.step: step.analyticsValue])
        }

        static func startSellingTapped(step: POSOnboardingGuideStep) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleOnboardingStartSellingTapped, properties: [Key.step: step.analyticsValue])
        }

        static func exitTapped(step: POSOnboardingGuideStep) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleOnboardingExitTapped, properties: [Key.step: step.analyticsValue])
        }

        static func videoTapped(step: POSOnboardingGuideStep) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleOnboardingVideoTapped, properties: [Key.step: step.analyticsValue])
        }
    }
}
