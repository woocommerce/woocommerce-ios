import SwiftUI

/// View to display basic details for a Blaze campaign.
///
struct BlazeCampaignItemView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: Layout.contentSpacing) {
            HStack(spacing: Layout.contentSpacing) {
                // campaign image
                VStack {
                    Image(uiImage: .productPlaceholderImage)
                        .resizable()
                        .frame(width: Layout.imageSize * scale, height: Layout.imageSize * scale)
                        .cornerRadius(Layout.cornerRadius)
                    Spacer()
                }

                // campaign status and name
                VStack(spacing: Layout.titleSpacing) {
                    BadgeView(text: "Active")
                    Text("Test")
                        .headlineStyle()
                }
                .fixedSize()

                Spacer()

                // disclosure indicator
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.headline)
            }

            // campaign stats
            AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .top) {
                Spacer()
                    .frame(width: Layout.imageSize * scale + Layout.contentSpacing)

                // campaign total impressions
                VStack(alignment: .leading, spacing: Layout.statsVerticalSpacing) {
                    Text(Localization.impressions)
                        .subheadlineStyle()
                    Text("1245")
                        .font(.title2)
                        .foregroundColor(.init(UIColor.text))
                }
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity)

                // campaign total clicks
                VStack(alignment: .leading, spacing: Layout.statsVerticalSpacing) {
                    Text(Localization.clicks)
                        .subheadlineStyle()
                    Text("1245")
                        .font(.title2)
                        .foregroundColor(.init(UIColor.text))
                }
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity)

                // campaign total budget
                VStack(alignment: .leading, spacing: Layout.statsVerticalSpacing) {
                    Text(Localization.budget)
                        .subheadlineStyle()
                    Text("1245")
                        .font(.title2)
                        .foregroundColor(.init(UIColor.text))
                }
                .fixedSize(horizontal: true, vertical: false)
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
    static var previews: some View {
        BlazeCampaignItemView()
    }
}
