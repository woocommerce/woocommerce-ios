import SwiftUI

/// View to display the introduction to the Blaze campaign
///

struct BlazeCampaignIntroView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        VStack(alignment: .leading) {
            Image(uiImage: .blaze)

            Text(Localization.title)
                .titleStyle()

            BulletPointView(text: Localization.descriptionPoint1)
            BulletPointView(text: Localization.descriptionPoint2)
            BulletPointView(text: Localization.descriptionPoint3)
            BulletPointView(text: Localization.descriptionPoint4)
        }
    }
}

struct BulletPointView: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text("• ")
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
        .padding(.bottom, 8)
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
    }
}

struct BlazeCampaignIntroView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeCampaignIntroView()
    }
}
