import SwiftUI
import Yosemite

/// View to display basic details for a Blaze campaign.
///
struct BlazeCampaignItemView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    private let campaign: BlazeCampaign

    init(campaign: BlazeCampaign) {
        self.campaign = campaign
    }

    var body: some View {
        VStack(spacing: Layout.contentSpacing) {
            AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .center, spacing: Layout.contentSpacing) {
                // campaign image
                VStack {
                    Image(uiImage: .productPlaceholderImage)
                        .resizable()
                        .frame(width: Layout.imageSize * scale, height: Layout.imageSize * scale)
                        .cornerRadius(Layout.cornerRadius)
                    Spacer()
                }

                // campaign status and name
                VStack(alignment: .leading, spacing: Layout.titleSpacing) {
                    BadgeView(
                        text: campaign.status.displayText.uppercased(),
                        customizations: .init(textColor: campaign.status.textColor,
                                              backgroundColor: campaign.status.backgroundColor)
                    )
                    Text(campaign.name)
                        .headlineStyle()
                }
                .fixedSize(horizontal: false, vertical: false)

                Spacer()

                // disclosure indicator
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.headline)
            }

            // campaign stats
            AdaptiveStack {
                Spacer()
                    .frame(width: Layout.imageSize * scale + Layout.contentSpacing)

                // campaign total impressions
                VStack(alignment: .leading, spacing: Layout.statsVerticalSpacing) {
                    Text(Localization.impressions)
                        .subheadlineStyle()
                    Text("\(campaign.totalImpressions)")
                        .font(.title2)
                        .foregroundColor(.init(UIColor.text))
                }
                .fixedSize()
                .frame(maxWidth: .infinity)

                // campaign total clicks
                VStack(alignment: .leading, spacing: Layout.statsVerticalSpacing) {
                    Text(Localization.clicks)
                        .subheadlineStyle()
                    Text("\(campaign.totalClicks)")
                        .font(.title2)
                        .foregroundColor(.init(UIColor.text))
                }
                .fixedSize()
                .frame(maxWidth: .infinity)

                // campaign total budget
                VStack(alignment: .leading, spacing: Layout.statsVerticalSpacing) {
                    Text(Localization.budget)
                        .subheadlineStyle()
                    Text(String(format: "%.2f", campaign.totalBudget))
                        .font(.title2)
                        .foregroundColor(.init(UIColor.text))
                }
                .fixedSize()
                .frame(maxWidth: .infinity)

                Spacer()
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .padding(Layout.contentSpacing)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(uiColor: .separator))
        }
        .padding(Layout.contentSpacing)
    }
}

private extension BlazeCampaignItemView {
    enum Layout {
        static let imageSize: CGFloat = 44
        static let contentSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let titleSpacing: CGFloat = 4
        static let statsVerticalSpacing: CGFloat = 6
    }

    enum Localization {
        static let impressions = NSLocalizedString("Impressions", comment: "Title label for the total impressions of a Blaze ads campaign")
        static let clicks = NSLocalizedString("Clicks", comment: "Title label for the total clicks of a Blaze ads campaign")
        static let budget = NSLocalizedString("Budget", comment: "Title label for the total budget of a Blaze campaign")
    }
}

struct BlazeCampaignItemView_Previews: PreviewProvider {
    static let campaign: BlazeCampaign = .init(siteID: 123,
                                               campaignID: 11,
                                               name: "Fluffy bunny pouch",
                                               uiStatus: BlazeCampaign.Status.finished.rawValue,
                                               contentImageURL: nil,
                                               contentClickURL: nil,
                                               totalImpressions: 112,
                                               totalClicks: 22,
                                               totalBudget: 35)
    static var previews: some View {
        BlazeCampaignItemView(campaign: campaign)
    }
}

// MARK: Customizations for campaign status
private extension BlazeCampaign.Status {
    var displayText: String {
        switch self {
        case .active:
            return Localization.active
        case .approved:
            return Localization.approved
        case .created:
            return Localization.created
        case .scheduled:
            return Localization.scheduled
        case .finished:
            return Localization.completed
        case .canceled:
            return Localization.canceled
        case .rejected:
            return Localization.rejected
        case .processing:
            return Localization.inModeration
        case .unknown:
            return Localization.unknown
        }
    }

    var textColor: Color {
        switch self {
        case .active, .approved, .created, .scheduled:
            return .withColorStudio(name: .green, shade: .shade60)
        case .finished:
            return .withColorStudio(name: .blue, shade: .shade80)
        case .canceled, .rejected:
            return .withColorStudio(name: .red, shade: .shade60)
        case .processing:
            return .withColorStudio(name: .yellow, shade: .shade70)
        case .unknown:
            return .withColorStudio(name: .gray, shade: .shade70)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .active, .approved, .created, .scheduled:
            return .withColorStudio(name: .green, shade: .shade5)
        case .finished:
            return .withColorStudio(name: .blue, shade: .shade5)
        case .canceled, .rejected:
            return .withColorStudio(name: .red, shade: .shade5)
        case .processing:
            return .withColorStudio(name: .yellow, shade: .shade5)
        case .unknown:
            return .withColorStudio(name: .gray, shade: .shade5)
        }
    }

    enum Localization {
        static let active = NSLocalizedString("Active", comment: "Status name of an active Blaze campaign")
        static let approved = NSLocalizedString("Approved", comment: "Status name of an approved Blaze campaign")
        static let created = NSLocalizedString("Created", comment: "Status name of a newly created Blaze campaign")
        static let scheduled = NSLocalizedString("Scheduled", comment: "Status name of a scheduled Blaze campaign")
        static let completed = NSLocalizedString("Completed", comment: "Status name of a completed Blaze campaign")
        static let canceled = NSLocalizedString("Canceled", comment: "Status name of a canceled Blaze campaign")
        static let rejected = NSLocalizedString("Rejected", comment: "Status name of a rejected Blaze campaign")
        static let inModeration = NSLocalizedString("In Moderation", comment: "Status name of a Blaze campaign under moderation")
        static let unknown = NSLocalizedString("Unknown", comment: "Status name of a Blaze campaign without specified state")
    }
}
