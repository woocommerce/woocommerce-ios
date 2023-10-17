import SwiftUI

/// View to display the introduction to the Blaze campaign
///
struct BlazeCampaignIntroView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.elementVerticalSpacing) {
                    ZStack {
                        Circle()
                            .fill(Color(.withColorStudio(.orange, shade: .shade40)).opacity(0.08))
                            .frame(width: Layout.logoBackgroundSize * scale, height: Layout.logoBackgroundSize * scale)

                        Image(uiImage: .blaze)
                            .resizable()
                            .frame(width: Layout.logoSize * scale, height: Layout.logoSize * scale)
                    }

                    Text(Localization.title)
                        .largeTitleStyle()

                    VStack(alignment: .leading, spacing: Layout.bulletPointVerticalSpacing) {
                        BulletPointView(text: Localization.descriptionPoint1)
                        BulletPointView(text: Localization.descriptionPoint2)
                        BulletPointView(text: Localization.descriptionPoint3)
                        BulletPointView(text: Localization.descriptionPoint4)
                    }
                }
                .padding(Layout.contentPadding)
            }
            .safeAreaInset(edge: .bottom) {
                VStack {
                    Divider()
                        .frame(height: Layout.dividerHeight)
                        .foregroundColor(Color(.separator))
                    Button(Localization.startBlazeCampaign) {
                        // todo
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(Layout.buttonPadding)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel) {
                        // todo
                    }
                }
            }
        }
    }
}

private extension BlazeCampaignIntroView {
    enum Localization {
        static let title = NSLocalizedString(
            "Drive more sales to your store with Blaze",
            comment: "Title for the Blaze campaign intro view"
        )
        static let descriptionPoint1 = NSLocalizedString(
            "Promote your product in just minutes.",
            comment: "First item in the description for Blaze campaign intro view"
        )
        static let descriptionPoint2 = NSLocalizedString(
            "Take control with just a few dollars a day. It’s budget-friendly.",
            comment: "Second item in the description for Blaze campaign intro view"
        )
        static let descriptionPoint3 = NSLocalizedString(
            "Reach millions on WordPress and Tumblr sites.",
            comment: "Third item in the description for Blaze campaign intro view"
        )
        static let descriptionPoint4 = NSLocalizedString(
            "Track performance, start and stop your Blaze campaign anytime.",
            comment: "Fourth item in the description for Blaze campaign intro view"
        )
        static let startBlazeCampaign = NSLocalizedString(
            "Start Blaze Campaign",
            comment: "Start Blaze Campaign button label"
        )
        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to dismiss Blaze Campaign intro."
        )
    }
}

private enum Layout {
    static let contentPadding: EdgeInsets = .init(top: 76, leading: 16, bottom: 16, trailing: 16)
    static let elementVerticalSpacing: CGFloat = 24
    static let bulletPointVerticalSpacing: CGFloat = 4
    static let dividerHeight: CGFloat = 1
    static let logoSize: CGFloat = 64
    static let logoBackgroundSize: CGFloat = 120
    static let buttonPadding: CGFloat = 16
}

struct BlazeCampaignIntroView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeCampaignIntroView()
    }
}
