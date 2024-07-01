import SwiftUI
import struct Yosemite.BlazeCampaignListItem

/// Customizations for campaign status
extension BlazeCampaignListItem.Status {
    var displayText: String {
        switch self {
        case .pending:
            return Localization.inModeration
        case .scheduled:
            return Localization.scheduled
        case .active:
            return Localization.active
        case .rejected:
            return Localization.rejected
        case .canceled:
            return Localization.canceled
        case .finished:
            return Localization.completed
        case .unknown:
            return Localization.unknown
        }
    }

    var textColor: Color {
        switch self {
        case .active:
            return .withColorStudio(name: .green, shade: .shade60)
        case .scheduled, .finished:
            return .withColorStudio(name: .blue, shade: .shade80)
        case .canceled, .rejected:
            return .withColorStudio(name: .red, shade: .shade60)
        case .pending:
            return .withColorStudio(name: .yellow, shade: .shade70)
        case .unknown:
            return .withColorStudio(name: .gray, shade: .shade70)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .active:
            return .withColorStudio(name: .green, shade: .shade5)
        case .scheduled, .finished:
            return .withColorStudio(name: .blue, shade: .shade5)
        case .canceled, .rejected:
            return .withColorStudio(name: .red, shade: .shade5)
        case .pending:
            return .withColorStudio(name: .yellow, shade: .shade5)
        case .unknown:
            return .withColorStudio(name: .gray, shade: .shade5)
        }
    }

    private enum Localization {
        static let inModeration = NSLocalizedString("blazeCampaignListItem.status.inModeration",
                                                    value: "In Moderation",
                                                    comment: "Status name of a pending Blaze campaign"
        )
        static let scheduled = NSLocalizedString("blazeCampaignListItem.status.scheduled",
                                                 value: "Scheduled",
                                                 comment: "Status name of a scheduled Blaze campaign"
        )
        static let active = NSLocalizedString("blazeCampaignListItem.status.active",
                                              value: "Active",
                                              comment: "Status name of an approved Blaze campaign"
        )
        static let rejected = NSLocalizedString("blazeCampaignListItem.status.rejected",
                                                value: "Rejected",
                                                comment: "Status name of a rejected Blaze campaign"
        )
        static let canceled = NSLocalizedString("blazeCampaignListItem.status.canceled",
                                                value: "Canceled",
                                                comment: "Status name of a canceled Blaze campaign"
        )
        static let completed = NSLocalizedString("blazeCampaignListItem.status.completed",
                                                 value: "Completed",
                                                 comment: "Status name of a completed Blaze campaign"
        )
        static let unknown = NSLocalizedString("blazeCampaignListItem.status.unknown",
                                               value: "Unknown",
                                               comment: "Status name of a Blaze campaign without specified state"
        )
    }
}
