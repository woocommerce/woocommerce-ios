import Foundation
import enum Yosemite.LocalAnnouncement
import struct WooFoundation.WooAnalyticsEvent

extension WooAnalyticsEvent {
    enum LocalAnnouncementModal {
        /// Event property keys.
        private enum Key: String {
            case announcement
        }

        /// Tracked when a local announcement modal is displayed.
        static func localAnnouncementDisplayed(announcement: LocalAnnouncement) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .localAnnouncementDisplayed,
                              properties: [Key.announcement.rawValue: announcement.analyticsValue])
        }

        /// Tracked when the user taps the CTA of a local announcement modal.
        static func localAnnouncementCallToActionTapped(announcement: LocalAnnouncement) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .localAnnouncementCallToActionTapped,
                              properties: [Key.announcement.rawValue: announcement.analyticsValue])
        }

        /// Tracked when the user taps to dismiss a local announcement modal.
        static func localAnnouncementDismissTapped(announcement: LocalAnnouncement) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .localAnnouncementDismissTapped,
                              properties: [Key.announcement.rawValue: announcement.analyticsValue])
        }
    }
}

private extension LocalAnnouncement {
    var analyticsValue: String {
        switch self {
            case .productDescriptionAI:
                return "product_description_ai"
        }
    }
}
