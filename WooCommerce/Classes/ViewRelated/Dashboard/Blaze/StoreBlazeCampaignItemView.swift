import Kingfisher
import StoreDesignSystem
import SwiftUI
import struct Yosemite.BlazeCampaignListItem

struct StoreBlazeCampaignItemView: View {
    @ScaledMetric(relativeTo: .body) private var imageSize = StoreSize.iconContainerSize

    let campaign: BlazeCampaignListItem

    var body: some View {
        StoreDashboardOutlinedContent {
            VStack(alignment: .leading, spacing: StoreSpacing.s5) {
                HStack(alignment: .top, spacing: StoreSpacing.s5) {
                    KFImage(URL(string: campaign.imageURL ?? ""))
                        .placeholder { Image(uiImage: .productPlaceholderImage) }
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(.rect(cornerRadius: StoreRadius.medium))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: StoreSpacing.s2) {
                        StoreBadge(campaign.status.displayText.uppercased(), tone: campaign.status.badgeTone)

                        Text(campaign.name)
                            .storeTextStyle(.titleMedium.strong)
                    }

                    Spacer(minLength: StoreSpacing.s0)
                    StoreIcon.AngleRight.regular.image(size: .largeIncreased)
                        .accessibilityHidden(true)
                }

                HStack(alignment: .firstTextBaseline, spacing: StoreSpacing.s5) {
                    Spacer()
                        .frame(width: imageSize)

                    VStack(alignment: .leading, spacing: StoreSpacing.s3) {
                        Text(Localization.clickthroughs)
                            .storeTextStyle(.bodyMedium)
                        (Text(campaign.humanReadableImpressions) +
                         Text(" ") +
                         Text(Image(systemName: "arrow.forward")) +
                         Text(" ") +
                         Text(campaign.humanReadableClicks))
                            .storeTextStyle(.titleLarge.emphasized)
                            .accessibilityLabel(Localization.clickThroughAccessibilityLabel(
                                impressions: campaign.impressions,
                                clicks: campaign.clicks
                            ))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: StoreSpacing.s3) {
                        Text(campaign.budgetTitle)
                            .storeTextStyle(.bodyMedium)
                            .lineLimit(1)
                        Text(campaign.budgetToDisplay)
                            .storeTextStyle(.titleLarge.emphasized)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .foregroundStyle(.storeOnSurface)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Localization.campaignAccessibilityLabel(
            campaignName: campaign.name,
            status: campaign.status.displayText
        ))
        .accessibilityHint(Localization.campaignAccessibilityHint)
    }
}

private extension BlazeCampaignListItem.Status {
    var badgeTone: StoreBadgeTone {
        switch self {
        case .active:
            .success
        case .scheduled, .finished:
            .info
        case .pending:
            .caution
        case .rejected, .canceled, .suspended:
            .error
        case .unknown:
            .neutral
        }
    }
}

private extension StoreBlazeCampaignItemView {
    enum Localization {
        static let clickthroughs = NSLocalizedString(
            "blazeCampaignItemView.clickthroughs",
            value: "Click-throughs",
            comment: "Title label for the total impressions and clicks of a Blaze ads campaign"
        )
        static let campaignAccessibilityHint = NSLocalizedString(
            "blazeCampaignItemView.campaignAccessibilityHint",
            value: "Tap to view campaign details",
            comment: "Accessibility hint for a Blaze campaign card"
        )

        static func campaignAccessibilityLabel(campaignName: String, status: String) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "blazeCampaignItemView.blazeCampaignAccessibilityLabelFormat",
                    value: "Blaze campaign for %1$@. %2$@",
                    comment: "Accessibility label format for a Blaze campaign card." +
                        " The %1$@ is a placeholder for the campaign name." +
                        " The %2$@ is a placeholder for the campaign status."
                ),
                campaignName,
                status
            )
        }

        static func clickThroughAccessibilityLabel(impressions: Int64, clicks: Int64) -> String {
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "blazeCampaignItemView.clickThroughAccessibilityLabelFormat",
                    value: "%1$d impressions, %2$d clicks",
                    comment: "Accessibility label format for a Blaze campaign's click-through rates. " +
                        "The placeholders are numbers of impressions and clicks. " +
                        "Reads as: '20000 impressions, 200 clicks'"
                ),
                impressions,
                clicks
            )
        }
    }
}
