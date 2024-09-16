import SwiftUI
import struct Yosemite.GoogleAdsCampaign

extension GoogleAdsCampaign.Status {
    var displayText: String {
        switch self {
        case .enabled:
            return Localization.enabled
        case .disabled:
            return Localization.disabled
        case .removed:
            return Localization.removed
        }
    }

    var textColor: Color {
        switch self {
        case .enabled:
            return .withColorStudio(name: .green, shade: .shade60)
        case .disabled:
            return .withColorStudio(name: .red, shade: .shade60)
        case .removed:
            return .withColorStudio(name: .gray, shade: .shade70)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .enabled:
            return .withColorStudio(name: .green, shade: .shade5)
        case .disabled:
            return .withColorStudio(name: .red, shade: .shade5)
        case .removed:
            return .withColorStudio(name: .gray, shade: .shade5)
        }
    }

    private enum Localization {
        static let enabled = NSLocalizedString(
            "googleAdsCampaign.status.enabled",
            value: "Enabled",
            comment: "Status name of a enabled Google Ads campaign"
        )
        static let disabled = NSLocalizedString(
            "googleAdsCampaign.status.disabled",
            value: "Disabled",
            comment: "Status name of a disabled Google Ads campaign"
        )
        static let removed = NSLocalizedString(
            "googleAdsCampaign.status.removed",
            value: "Removed",
            comment: "Status name of a removed Google Ads campaign"
        )
    }
}
