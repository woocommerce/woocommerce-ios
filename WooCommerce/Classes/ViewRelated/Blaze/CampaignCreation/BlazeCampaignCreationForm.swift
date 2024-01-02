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
        VStack(spacing: Layout.contentPadding) {
            VStack(alignment: .leading, spacing: Layout.contentMargin) {
                // TODO: use product image here
                // Product image
                Image(uiImage: .blazeIntroIllustration)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(Layout.cornerRadius)

                // TODO: dynamic content
                // Tagline
                Text("From $99")
                    .captionStyle()

                HStack(spacing: Layout.contentPadding) {
                    // TODO: dynamic content
                    // Description
                    Text("Get the latest white shirt for a stylish look")
                        .fontWeight(.semibold)
                        .headlineStyle()
                        .multilineTextAlignment(.leading)

                    // Simulate shop button
                    Text(Localization.shopNow)
                        .fontWeight(.semibold)
                        .captionStyle()
                        .padding(Layout.contentMargin)
                        .background(Color(uiColor: .systemGray6))
                        .cornerRadius(Layout.adButtonCornerRadius)
                }
            }
            .padding(Layout.contentPadding)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(Layout.cornerRadius)

            // Button to edit ad details
            Button(action: {
                // TODO
            }, label: {
                Text(Localization.editAd)
                    .fontWeight(.semibold)
                    .font(.body)
                    .foregroundColor(.accentColor)
            })
            .buttonStyle(.plain)
        }
        .padding(Layout.contentPadding)
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(Layout.cornerRadius)
        .padding(Layout.contentPadding)
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
        static let details = NSLocalizedString(
            "blazeCampaignCreationForm.details",
            value: "Details",
            comment: "Section title on the Blaze campaign creation screen"
        )
        static let budget = NSLocalizedString(
            "blazeCampaignCreationForm.budget",
            value: "Budget",
            comment: "Title of the Budget field on the Blaze campaign creation screen"
        )
        static let language = NSLocalizedString(
            "blazeCampaignCreationForm.language",
            value: "Language",
            comment: "Title of the Language field on the Blaze campaign creation screen"
        )
        static let devices = NSLocalizedString(
            "blazeCampaignCreationForm.devices",
            value: "Devices",
            comment: "Title of the Devices field on the Blaze campaign creation screen"
        )
        static let location = NSLocalizedString(
            "blazeCampaignCreationForm.location",
            value: "Location",
            comment: "Title of the Location field on the Blaze campaign creation screen"
        )
        static let interests = NSLocalizedString(
            "blazeCampaignCreationForm.interests",
            value: "Interests",
            comment: "Title of the Interests field on the Blaze campaign creation screen"
        )
        static let adDestination = NSLocalizedString(
            "blazeCampaignCreationForm.adDestination",
            value: "Ad destination",
            comment: "Title of the Ad destination field on the Blaze campaign creation screen"
        )
        static let confirmDetails = NSLocalizedString(
            "blazeCampaignCreationForm.confirmDetails",
            value: "Confirm Details",
            comment: "Button to confirm ad details on the Blaze campaign creation screen"
        )
    }
}

struct BlazeCampaignCreationForm_Previews: PreviewProvider {
    static var previews: some View {
        BlazeCampaignCreationForm(viewModel: .init(siteID: 123) {})
    }
}
