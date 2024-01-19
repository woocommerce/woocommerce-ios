import SwiftUI

struct BlazeCampaignCreationLoadingView: View {
    var body: some View {
        ScrollableVStack {
            Spacer()

            VStack(alignment: .center, spacing: Layout.vSpacing) {
                Image(uiImage: .wooHourglass)

                Text(Localization.title)
                    .secondaryTitleStyle()
                    .multilineTextAlignment(.center)

                ProgressView()
            }

            Spacer()
        }
    }
}

private extension BlazeCampaignCreationLoadingView {
    enum Layout {
        static let vSpacing: CGFloat = 24
    }

    enum Localization {
        static let title = NSLocalizedString(
            "blazeCampaignCreationLoadingView.Message",
            value: "Creating your campaign",
            comment: "Message in the Blaze campaign creation loading screen"
        )
    }
}

struct BlazeCampaignCreationLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeCampaignCreationLoadingView()
    }
}
