import SwiftUI

/// Hosting controller for `BlazeCampaignCreationForm`
final class BlazeCampaignCreationFormHostingController: UIHostingController<BlazeCampaignCreationForm> {
    init(viewModel: BlazeCampaignCreationFormViewModel) {
        super.init(rootView: .init(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Form to enter details for creating a new Blaze campaign.
struct BlazeCampaignCreationForm: View {
    @ObservedObject private var viewModel: BlazeCampaignCreationFormViewModel

    init(viewModel: BlazeCampaignCreationFormViewModel) {
        self.viewModel = viewModel
    }

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
                // Product image
                Image(uiImage: .blazeIntroIllustration)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(Layout.cornerRadius)

                // Tagline
                Text("From $99")
                    .captionStyle()

                HStack {
                    // Description
                    Text("Get the latest white shirt for a stylish look")
                        .multilineTextAlignment(.leading)
                    Spacer()
                    // Simulate shop button
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

            // Button to edit ad details
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
        BlazeCampaignCreationForm(viewModel: .init(siteID: 123) {})
    }
}
