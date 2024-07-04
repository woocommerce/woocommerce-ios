import SwiftUI
import struct Yosemite.GoogleAdsCampaign

struct GoogleAdsCampaignDetailView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    private let campaign: GoogleAdsCampaign

    init(campaign: GoogleAdsCampaign) {
        self.campaign = campaign
    }

    var body: some View {
        VStack(spacing: Layout.contentSpacing) {
            AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .center, spacing: Layout.contentSpacing) {
                // campaign image
                VStack {
                    Image(uiImage: .googleLogo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Layout.imageSize * scale, height: Layout.imageSize * scale)
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
                Image(systemName: "chevron.forward")
                    .foregroundColor(.secondary)
                    .font(.headline)
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

private extension GoogleAdsCampaignDetailView {
    enum Layout {
        static let imageSize: CGFloat = 44
        static let contentSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let titleSpacing: CGFloat = 4
        static let statsVerticalSpacing: CGFloat = 6
        static let strokeWidth: CGFloat = 0.5
    }
}

#Preview {
    GoogleAdsCampaignDetailView(campaign: GoogleAdsCampaign(id: 123,
                                                            name: "Test campaign",
                                                            rawStatus: "enabled",
                                                            rawType: "test",
                                                            amount: 10,
                                                            country: "US",
                                                            targetedLocations: ["US"]))
}
