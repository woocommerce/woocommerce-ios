import SwiftUI

struct BlazeCampaignCreationForm: View {
    var body: some View {
        ScrollView {
            adPreview
            Spacer()
        }
        .navigationTitle(Localization.title)
    }
}

private extension BlazeCampaignCreationForm {
    var adPreview: some View {
        VStack {
            VStack(alignment: .leading, spacing: Layout.contentMargin) {
                // TODO: use product image here
                Image(uiImage: .blazeIntroIllustration)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(Layout.cornerRadius)

                // TODO: dynamic text
                Text("From $99")
                    .captionStyle()

                HStack {
                    // TODO: dynamic text
                    Text("Get the latest white shirt for a stylish look")
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Text(Localization.shopNow)
                        .fontWeight(.semibold)
                        .captionStyle()
                        .padding(Layout.contentMargin)
                        .background(Color(uiColor: .systemGray))
                        .cornerRadius(Layout.adButtonCornerRadius)
                }
            }
            .padding(Layout.contentMargin)
            .cornerRadius(Layout.cornerRadius)
            .padding(Layout.contentPadding)

            Button(Localization.editAd) {
                // TODO
            }
            .buttonStyle(.plain)
        }
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(Layout.cornerRadius)
        .padding(Layout.contentMargin)
    }
}

private extension BlazeCampaignCreationForm {
    enum Layout {
        static let contentMargin: CGFloat = 8
        static let contentPadding: CGFloat = 16
        static let imagePadding: CGFloat = 8
        static let cornerRadius: CGFloat = 8
        static let adButtonCornerRadius: CGFloat = 4
    }

    enum Localization {
        static let title = NSLocalizedString(
            "blazeCampaignCreationForm.title",
            value: "Preview",
            comment: "Title of the Blaze campaign creation screen"
        )
        static let shopNow = NSLocalizedString(
            "blazeCampaignCreationForm.shopNow",
            value: "Shop Now",
            comment: "Button to shop on the Blaze ad preview"
        )
        static let editAd = NSLocalizedString(
            "blazeCampaignCreationForm.editAd",
            value: "Edit ad",
            comment: "Button to edit ad details on the Blaze campaign creation screen"
        )
    }
}

struct BlazeCampaignCreationForm_Previews: PreviewProvider {
    static var previews: some View {
        BlazeCampaignCreationForm()
    }
}
