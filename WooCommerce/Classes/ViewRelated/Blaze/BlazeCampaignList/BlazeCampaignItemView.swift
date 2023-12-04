import SwiftUI
import struct Yosemite.BlazeCampaign
import Kingfisher

/// View to display basic details for a Blaze campaign.
///
struct BlazeCampaignItemView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    private let campaign: BlazeCampaign
    private let showBudget: Bool

    init(campaign: BlazeCampaign,
         showBudget: Bool = true) {
        self.campaign = campaign
        self.showBudget = showBudget
    }

    var body: some View {
        VStack(spacing: Layout.contentSpacing) {
            AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .center, spacing: Layout.contentSpacing) {
                // campaign image
                VStack {
                    KFImage(URL(string: campaign.contentImageURL ?? ""))
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
                        .font(.headline)
                        .fontWeight(.semibold)
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
                        .fontWeight(.semibold)
                        .foregroundColor(.init(UIColor.text))
                }
                .fixedSize()
                .frame(maxWidth: .infinity, alignment: .leading)

                // campaign total clicks
                VStack(alignment: .leading, spacing: Layout.statsVerticalSpacing) {
                    Text(Localization.clicks)
                        .subheadlineStyle()
                    Text("\(campaign.totalClicks)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.init(UIColor.text))
                }
                .fixedSize()
                .frame(maxWidth: .infinity, alignment: .leading)

                // campaign total budget
                VStack(alignment: .leading, spacing: Layout.statsVerticalSpacing) {
                    Text(Localization.budget)
                        .subheadlineStyle()
                    Text(String(format: "%.2f", campaign.totalBudget))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.init(UIColor.text))
                }
                .fixedSize()
                .frame(maxWidth: .infinity, alignment: .leading)
                .renderedIf(showBudget)

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

    enum Localization {
        static let impressions = NSLocalizedString("Impressions", comment: "Title label for the total impressions of a Blaze ads campaign")
        static let clicks = NSLocalizedString("Clicks", comment: "Title label for the total clicks of a Blaze ads campaign")
        static let budget = NSLocalizedString("Budget", comment: "Title label for the total budget of a Blaze campaign")
    }
}

struct BlazeCampaignItemView_Previews: PreviewProvider {
    static let campaign: BlazeCampaign = .init(siteID: 123,
                                               campaignID: 11,
                                               productID: 33,
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
