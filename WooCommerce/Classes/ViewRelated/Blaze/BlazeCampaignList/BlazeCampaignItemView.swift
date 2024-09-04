import SwiftUI
import struct Yosemite.BlazeCampaignListItem
import Kingfisher

/// View to display basic details for a Blaze campaign.
///
struct BlazeCampaignItemView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    private let campaign: BlazeCampaignListItem

    init(campaign: BlazeCampaignListItem) {
        self.campaign = campaign
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.contentSpacing) {
            AdaptiveStack(horizontalAlignment: .leading,
                          verticalAlignment: .center,
                          spacing: Layout.contentSpacing) {
                // campaign image
                VStack {
                    KFImage(URL(string: campaign.imageURL ?? ""))
                        .placeholder {
                            Image(uiImage: .productPlaceholderImage)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
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
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                // disclosure indicator
                Image(systemName: "chevron.forward")
                    .foregroundColor(.secondary)
                    .font(.headline)
            }

            // campaign stats
            AdaptiveStack(horizontalAlignment: .leading,
                          verticalAlignment: .firstTextBaseline) {

                Spacer()
                    .frame(width: Layout.imageSize * scale + Layout.contentSpacing)

                // campaign total impressions -> clicks
                VStack(alignment: .leading, spacing: Layout.statsVerticalSpacing) {
                    Text(Localization.clickthroughs)
                        .subheadlineStyle()
                        .lineLimit(1)

                    (Text("\(campaign.impressions) ").font(.title2).fontWeight(.semibold) +
                     Text(Image(systemName: "arrow.forward")) +
                     Text(" \(campaign.clicks)").font(.title2).fontWeight(.semibold))
                        .foregroundStyle(Color(.text))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // campaign total budget
                VStack(alignment: .leading, spacing: Layout.statsVerticalSpacing) {
                    Text(campaign.budgetTitle)
                        .subheadlineStyle()
                        .lineLimit(1)
                    Text(campaign.budgetToDisplay)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.init(UIColor.text))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .padding(Layout.contentSpacing)
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Color(uiColor: .init(light: UIColor.clear,
                                           dark: UIColor.systemGray5)))
        )
        .overlay {
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(uiColor: .separator), lineWidth: Layout.strokeWidth)
        }
        .padding(Layout.strokeWidth)
    }
}

private extension BlazeCampaignItemView {
    enum Layout {
        static let imageSize: CGFloat = 44
        static let contentSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let titleSpacing: CGFloat = 4
        static let statsVerticalSpacing: CGFloat = 6
        static let strokeWidth: CGFloat = 0.5
    }

    enum Constants {
        static let centsToUnit: Double = 100
    }

    enum Localization {
        static let clickthroughs = NSLocalizedString(
            "blazeCampaignItemView.clickthroughs",
            value: "Click-throughs",
            comment: "Title label for the total impressions and clicks of a Blaze ads campaign"
        )
    }
}

struct BlazeCampaignItemView_Previews: PreviewProvider {
    static let campaign: BlazeCampaignListItem = .init(siteID: 123,
                                                       campaignID: "11",
                                                       productID: 33,
                                                       name: "Fluffy bunny pouch",
                                                       textSnippet: "Buy now!",
                                                       uiStatus: BlazeCampaignListItem.Status.suspended.rawValue,
                                                       imageURL: nil,
                                                       targetUrl: nil,
                                                       impressions: 112,
                                                       clicks: 22,
                                                       totalBudget: 35,
                                                       spentBudget: 4,
                                                       budgetMode: .total,
                                                       budgetAmount: 0,
                                                       budgetCurrency: "USD",
                                                       isEvergreen: false,
                                                       durationDays: 5,
                                                       startTime: Date())
    static var previews: some View {
        BlazeCampaignItemView(campaign: campaign)
    }
}
