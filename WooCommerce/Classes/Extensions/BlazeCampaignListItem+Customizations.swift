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
        static let inModeration = NSLocalizedString("In Moderation", comment: "Status name of a pending Blaze campaign")
        static let scheduled = NSLocalizedString("Scheduled", comment: "Status name of a scheduled Blaze campaign")
        static let active = NSLocalizedString("Active", comment: "Status name of an approved Blaze campaign")
        static let rejected = NSLocalizedString("Rejected", comment: "Status name of a rejected Blaze campaign")
        static let canceled = NSLocalizedString("Canceled", comment: "Status name of a canceled Blaze campaign")
        static let completed = NSLocalizedString("Completed", comment: "Status name of a completed Blaze campaign")
        static let unknown = NSLocalizedString("Unknown", comment: "Status name of a Blaze campaign without specified state")
    }
}
