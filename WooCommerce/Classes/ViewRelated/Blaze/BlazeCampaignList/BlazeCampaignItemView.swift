import SwiftUI
import Yosemite
import Kingfisher

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