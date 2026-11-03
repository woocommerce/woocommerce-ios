import Kingfisher
import StoreDesignSystem
import SwiftUI
import struct Yosemite.BlazeCampaignListItem

struct StoreBlazeCampaignItemView: View {
    @ScaledMetric private var scale: CGFloat = 1

    let campaign: BlazeCampaignListItem

    var body: some View {
        StoreDashboardOutlinedContent {
            VStack(alignment: .leading, spacing: StoreSpacing.s5) {
                HStack(alignment: .top, spacing: StoreSpacing.s5) {
                    KFImage(URL(string: campaign.imageURL ?? ""))
                        .placeholder { Image(uiImage: .productPlaceholderImage) }
                        .resizable()
                        .scaledToFill()
                        .frame(width: Layout.imageSize * scale, height: Layout.imageSize * scale)
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
                        .frame(width: Layout.imageSize * scale)

                    VStack(alignment: .leading, spacing: StoreSpacing.s3) {
                        Text(Localization.clickthroughs)
                            .storeTextStyle(.bodyMedium)
                        Text("\(campaign.humanReadableImpressions) → \(campaign.humanReadableClicks)")
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
    enum Layout {
        static let imageSize: CGFloat = 44
    }

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
                    comment: "Accessibility label for a Blaze campaign. The placeholders are its name and status."
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
                    comment: "Accessibility label for a Blaze campaign's impressions and clicks."
                ),
                impressions,
                clicks
            )
        }
    }
}
