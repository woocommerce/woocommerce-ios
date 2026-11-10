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
                AdaptiveStack(horizontalAlignment: .leading,
                              verticalAlignment: .top,
                              spacing: StoreSpacing.s5) {
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
                        .flipsForRightToLeftLayoutDirection(true)
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Localization.campaignAccessibilityLabel(
                    campaignName: campaign.name,
                    status: campaign.status.displayText
                ))
                .accessibilityHint(Localization.campaignAccessibilityHint)

                CollapsibleHStack(horizontalAlignment: .leading,
                                  verticalAlignment: .firstTextBaseline,
                                  spacing: StoreSpacing.s5) {
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
    typealias Localization = BlazeCampaignItemView.Localization
}
