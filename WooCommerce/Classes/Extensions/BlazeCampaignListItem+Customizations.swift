import SwiftUI
import WooFoundation
import struct Yosemite.BlazeCampaignListItem

/// Helpers for displaying campaign details
extension BlazeCampaignListItem {
    var isActive: Bool {
        status == .pending || status == .scheduled || status == .active
    }

    var humanReadableImpressions: String {
        let doubleValue = Double(impressions)
        return doubleValue.humanReadableString(shouldHideDecimalsForIntegerAbbreviatedValue: true).uppercased()
    }

    var humanReadableClicks: String {
        let doubleValue = Double(clicks)
        return doubleValue.humanReadableString(shouldHideDecimalsForIntegerAbbreviatedValue: true).uppercased()
    }

    var budgetToDisplay: String {
        guard isEvergreen else {
            /// For non-evergreen campaigns, display remaining budget for active campaigns
            /// and total budget otherwise.
            let budget = isActive ? totalBudget - spentBudget : totalBudget
            return String(format: "$%.0f", budget)
        }

        /// For evergreen campaigns, calculate the weekly amount to display.
        let weeklyBudget = totalBudget / Double(durationDays) * Double(BlazeBudgetSettingViewModel.Constants.dayCountInWeek)
        return String(format: "$%.0f", weeklyBudget)
    }

    var budgetTitle: String {
        if isEvergreen {
            Localization.weeklyBudget
        } else if isActive {
            Localization.remainingBudget
        } else {
            Localization.totalBudget
        }
    }

    private enum Localization {
        static let weeklyBudget = NSLocalizedString(
            "blazeCampaignListItem.weeklyBudget",
            value: "Weekly",
            comment: "Title of the budget field of a Blaze campaign without an end date."
        )
        static let totalBudget = NSLocalizedString(
            "blazeCampaignListItem.totalBudget",
            value: "Total",
            comment: "Title of the total budget field of a Blaze campaign with an end date."
        )
        static let remainingBudget = NSLocalizedString(
            "blazeCampaignListItem.remainingBudget",
            value: "Remaining",
            comment: "Title of the remaining budget field of a Blaze campaign with an end date."
        )
    }
}

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
        case .suspended:
            return Localization.suspended
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
        case .suspended:
            return .white
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
        case .suspended:
            return .withColorStudio(name: .red, shade: .shade60)
        case .pending:
            return .withColorStudio(name: .yellow, shade: .shade5)
        case .unknown:
            return .withColorStudio(name: .gray, shade: .shade5)
        }
    }

    private enum Localization {
        static let inModeration = NSLocalizedString("blazeCampaignListItem.status.inModeration",
                                                    value: "In Moderation",
                                                    comment: "This text appears as a status label for Blaze advertising campaigns that are currently awaiting approval or review. It is displayed in a campaign list item to indicate the campaign's pending moderation state."
        )
        static let scheduled = NSLocalizedString("blazeCampaignListItem.status.scheduled",
                                                 value: "Scheduled",
                                                 comment: "A status label that appears in the Blaze campaign list to indicate that a marketing campaign has been scheduled but is not yet active. This status text is displayed alongside other campaign information and is color-coded with blue styling."
        )
        static let active = NSLocalizedString("blazeCampaignListItem.status.active",
                                              value: "Active",
                                              comment: "This text appears as a status label for Blaze advertising campaigns that are currently running and approved. It's displayed in a campaign list view to indicate the campaign's operational state."
        )
        static let rejected = NSLocalizedString("blazeCampaignListItem.status.rejected",
                                                value: "Rejected",
                                                comment: "Status label displayed in the Blaze campaign list to indicate that an advertising campaign has been rejected and will not run."
        )
        static let canceled = NSLocalizedString("blazeCampaignListItem.status.canceled",
                                                value: "Canceled",
                                                comment: "This text appears as a status label for Blaze advertising campaigns that have been canceled by the user or system. It's displayed in a campaign list item to indicate the current state of the campaign."
        )
        static let completed = NSLocalizedString("blazeCampaignListItem.status.completed",
                                                 value: "Completed",
                                                 comment: "This text appears as a status label in the Blaze campaign list to indicate that an advertising campaign has finished running. It's one of several possible campaign states displayed to help users understand the current status of their marketing campaigns."
        )
        static let suspended = NSLocalizedString("blazeCampaignListItem.status.suspended",
                                                 value: "Suspended",
                                                 comment: "This text appears as a status label in the Blaze campaign list view, indicating that a promotional campaign has been temporarily suspended and is not currently running."
        )
        static let unknown = NSLocalizedString("blazeCampaignListItem.status.unknown",
                                               value: "Unknown",
                                               comment: "This text appears as a status label for Blaze advertising campaigns when the campaign's current state cannot be determined or is not recognized by the system. It displays in a campaign list view alongside other possible statuses like Active, Rejected, Canceled, Completed, and Suspended."
        )
    }
}
