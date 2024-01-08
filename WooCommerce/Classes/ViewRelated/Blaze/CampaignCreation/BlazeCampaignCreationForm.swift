import SwiftUI

/// Hosting controller for `BlazeCampaignCreationForm`
final class BlazeCampaignCreationFormHostingController: UIHostingController<BlazeCampaignCreationForm> {
    private let viewModel: BlazeCampaignCreationFormViewModel

    init(viewModel: BlazeCampaignCreationFormViewModel) {
        self.viewModel = viewModel
        super.init(rootView: .init(viewModel: viewModel))
        self.viewModel.onEditAd = { [weak self] in
            self?.navigateToEditAd()
        }
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension BlazeCampaignCreationFormHostingController {
    func navigateToEditAd() {
        // TODO: Send ad data to edit screen
        let adData = BlazeEditAdData(image: .init(image: .blazeIntroIllustration, source: .asset(asset: .init())),
                                     tagline: "From $99",
                                     description: "Get the latest white shirt for a stylish look")
        let vc = BlazeEditAdHostingController(viewModel: BlazeEditAdViewModel(siteID: viewModel.siteID,
                                                                              adData: adData,
                                                                              onSave: { _ in
            // TODO: Update ad with edited data
        }))
        present(vc, animated: true)
    }
}

/// Form to enter details for creating a new Blaze campaign.
struct BlazeCampaignCreationForm: View {
    @ObservedObject private var viewModel: BlazeCampaignCreationFormViewModel

    @State private var isShowingAdDestinationScreen = false

    init(viewModel: BlazeCampaignCreationFormViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.contentPadding) {
                adPreview

                Text(Localization.details)
                    .subheadlineStyle()
                    .foregroundColor(.init(uiColor: .text))

                // Budget
                detailView(title: Localization.budget, content: "$35, 7 days from Dec 13") {
                    // TODO: open budget screen
                }
                .overlay { roundedRectangleBorder }

                VStack(spacing: 0) {
                    // Language
                    detailView(title: Localization.language, content: "English, Chinese") {
                        // TODO: open language screen
                    }

                    divider

                    // Devices
                    detailView(title: Localization.devices, content: "All") {
                        // TODO: open devices screen
                    }

                    divider

                    // Location
                    detailView(title: Localization.location, content: "All") {
                        // TODO: open location screen
                    }

                    divider

                    // Interests
                    detailView(title: Localization.interests, content: "Sports, Styles & Fashion, Travel, Shopping") {
                        // TODO: open interests screen
                    }
                }
                .overlay { roundedRectangleBorder }

                // Ad destination
                detailView(title: Localization.adDestination, content: "https://example.com") {
                    isShowingAdDestinationScreen = true
                }
                .overlay { roundedRectangleBorder }
            }
            .padding(.horizontal, Layout.contentPadding)
        }
        .navigationTitle(Localization.title)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()

                Button(Localization.confirmDetails) {
                    // TODO: handle campaign creation
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: false))
                .padding(Layout.contentPadding)
            }
            .background(Color(uiColor: .systemBackground))
        }
        .sheet(isPresented: $isShowingAdDestinationScreen) {
            BlazeAdDestinationSettingView(viewModel: .init(productURL: "https://woo.com/product/", homeURL: "https://woo.com/"))
        }
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
            .shadow(color: .black.opacity(0.05),
                    radius: Layout.shadowRadius,
                    x: 0,
                    y: Layout.shadowYOffset)

            // Button to edit ad details
            Button(action: {
                // TODO
                viewModel.didTapEditAd()
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
        .padding(.vertical, Layout.contentPadding)
    }

    func detailView(title: String, content: String, action: @escaping () -> Void) -> some View {
        Button(action: action, label: {
            HStack {
                VStack(alignment: .leading, spacing: Layout.detailContentSpacing) {
                    Text(title)
                        .bodyStyle()
                    Text(content)
                        .secondaryBodyStyle()
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .secondaryBodyStyle()
            }
            .padding(.horizontal, Layout.contentPadding)
            .padding(.vertical, Layout.contentMargin)
        })
    }

    var divider: some View {
        Divider()
            .frame(height: Layout.strokeWidth)
            .foregroundColor(Color(uiColor: .separator))
    }

    var roundedRectangleBorder: some View {
        RoundedRectangle(cornerRadius: Layout.cornerRadius)
            .stroke(Color(uiColor: .separator), lineWidth: Layout.strokeWidth)
    }
}

private extension BlazeCampaignCreationForm {
    enum Layout {
        static let contentMargin: CGFloat = 8
        static let contentPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let adButtonCornerRadius: CGFloat = 4
        static let strokeWidth: CGFloat = 1
        static let detailContentSpacing: CGFloat = 4
        static let shadowRadius: CGFloat = 2
        static let shadowYOffset: CGFloat = 2
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
