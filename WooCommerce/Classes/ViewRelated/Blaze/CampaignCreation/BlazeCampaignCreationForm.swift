import SwiftUI

/// Hosting controller for `BlazeCampaignCreationForm`
final class BlazeCampaignCreationFormHostingController: UIHostingController<BlazeCampaignCreationForm> {
    private let viewModel: BlazeCampaignCreationFormViewModel

    init(viewModel: BlazeCampaignCreationFormViewModel) {
        self.viewModel = viewModel
        super.init(rootView: BlazeCampaignCreationForm(viewModel: viewModel))
        self.viewModel.onEditAd = { [weak self] in
            self?.navigateToEditAd()
        }
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        view.backgroundColor = .listBackground
    }
}

private extension BlazeCampaignCreationFormHostingController {
    func configureNavigation() {
        title = Localization.title
    }

    func navigateToEditAd() {
        let vc = BlazeEditAdHostingController(viewModel: viewModel.editAdViewModel)
        present(vc, animated: true)
    }
}

private extension BlazeCampaignCreationFormHostingController {
    enum Localization {
        static let title = NSLocalizedString(
            "blazeCampaignCreationForm.title",
            value: "Preview",
            comment: "Title of the Blaze campaign creation screen"
        )
    }

    enum Constants {
        static let supportTag = "origin:blaze-native-campaign-creation"
    }
}

/// Form to enter details for creating a new Blaze campaign.
struct BlazeCampaignCreationForm: View {
    @ObservedObject private var viewModel: BlazeCampaignCreationFormViewModel

    @Environment(\.colorScheme) var colorScheme
    @ScaledMetric private var scale: CGFloat = 1.0

    @State private var isShowingBudgetSetting = false
    @State private var isShowingLanguagePicker = false
    @State private var isShowingAdDestinationScreen = false
    @State private var isShowingDevicePicker = false
    @State private var isShowingTopicPicker = false
    @State private var isShowingLocationPicker = false
    @State private var isShowingAISuggestionsErrorAlert: Bool = false
    @State private var isShowingSupport: Bool = false

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
                detailView(title: Localization.budget, content: viewModel.budgetDetailText) {
                    isShowingBudgetSetting = true
                }
                .background(Constants.cellColor)
                .overlay { roundedRectangleBorder }
                .padding(.bottom, Layout.contentMargin)

                Text(Localization.audience)
                    .subheadlineStyle()
                    .foregroundColor(.init(uiColor: .text))

                VStack(spacing: 0) {
                    // Language
                    detailView(title: Localization.language, content: viewModel.targetLanguageText) {
                        isShowingLanguagePicker = true
                    }

                    divider

                    // Devices
                    detailView(title: Localization.devices, content: viewModel.targetDeviceText) {
                        isShowingDevicePicker = true
                    }

                    divider

                    // Location
                    detailView(title: Localization.location, content: viewModel.targetLocationText) {
                        isShowingLocationPicker = true
                    }

                    divider

                    // Interests
                    detailView(title: Localization.interests, content: viewModel.targetTopicText) {
                        isShowingTopicPicker = true
                    }
                }
                .background(Constants.cellColor)
                .overlay { roundedRectangleBorder }

                // Ad destination
                if viewModel.adDestinationViewModel != nil {
                    detailView(title: Localization.adDestination,
                               content: viewModel.finalDestinationURL.isNotEmpty ? viewModel.finalDestinationURL : Localization.adDestinationEmpty,
                               isContentSingleLine: true) {
                        isShowingAdDestinationScreen = true
                    }
                    .background(Constants.cellColor)
                    .overlay { roundedRectangleBorder }
                }
            }
            .padding(.horizontal, Layout.contentPadding)
        }
        .background(Constants.backgroundViewColor)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()

                Button {
                    viewModel.didTapConfirmDetails()
                } label: {
                    Text(Localization.confirmDetails)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(Layout.contentPadding)
                .disabled(!viewModel.canConfirmDetails)
            }
            .background(Constants.backgroundViewColor)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(Localization.help) {
                    isShowingSupport = true
                }
            }
        }
        .sheet(isPresented: $isShowingSupport) {
            supportForm
        }
        .sheet(isPresented: $isShowingBudgetSetting) {
            BlazeBudgetSettingView(viewModel: viewModel.budgetSettingViewModel)
        }
        .sheet(isPresented: $isShowingLanguagePicker) {
            BlazeTargetLanguagePickerView(viewModel: viewModel.targetLanguageViewModel) {
                isShowingLanguagePicker = false
            }
        }
        .sheet(isPresented: $isShowingAdDestinationScreen) {
            if let viewModel = viewModel.adDestinationViewModel {
                BlazeAdDestinationSettingView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $isShowingDevicePicker) {
            BlazeTargetDevicePickerView(viewModel: viewModel.targetDeviceViewModel) {
                isShowingDevicePicker = false
            }
        }
        .sheet(isPresented: $isShowingTopicPicker) {
            BlazeTargetTopicPickerView(viewModel: viewModel.targetTopicViewModel) {
                isShowingTopicPicker = false
            }
        }
        .sheet(isPresented: $isShowingLocationPicker) {
            BlazeTargetLocationPickerView(viewModel: viewModel.targetLocationViewModel) {
                isShowingLocationPicker = false
            }
        }
        .onChange(of: viewModel.error) { newValue in
            isShowingAISuggestionsErrorAlert = newValue == .failedToLoadAISuggestions
        }
        .alert(Localization.AISuggestionsErrorAlert.fetchingAISuggestions, isPresented: $isShowingAISuggestionsErrorAlert) {
            Button(Localization.AISuggestionsErrorAlert.cancel, role: .cancel) { }

            Button(Localization.AISuggestionsErrorAlert.retry) {
                Task {
                    await viewModel.loadAISuggestions()
                }
            }
        }
        .alert(Localization.NoImageErrorAlert.noImageFound, isPresented: $viewModel.isShowingMissingImageErrorAlert) {
            Button(Localization.NoImageErrorAlert.cancel, role: .cancel) { }

            Button(Localization.NoImageErrorAlert.addImage) {
                viewModel.didTapEditAd()
            }
        }
        .alert(Localization.NoDestinationURLAlert.noURLFound, isPresented: $viewModel.isShowingMissingDestinationURLAlert) {
            Button(Localization.NoDestinationURLAlert.cancel, role: .cancel) { }

            Button(Localization.NoDestinationURLAlert.selectURL) {
                isShowingAdDestinationScreen = true
            }
        }
        .onAppear() {
            viewModel.onAppear()
        }
        .frame(maxWidth: Layout.maxWidth)
        .task {
            await viewModel.onLoad()
        }
        if let confirmPaymentViewModel = viewModel.confirmPaymentViewModel {
            LazyNavigationLink(destination: BlazeConfirmPaymentView(viewModel: confirmPaymentViewModel),
                               isActive: $viewModel.isShowingPaymentInfo) {
                EmptyView()
            }
        }
    }
}

private extension BlazeCampaignCreationForm {
    var adPreview: some View {
        VStack(spacing: Layout.contentPadding) {
            VStack(alignment: .leading, spacing: Layout.contentMargin) {
                // Image
                Image(uiImage: viewModel.image?.image ?? .blazeProductPlaceholder)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(Layout.cornerRadius)

                // Tagline
                Text(viewModel.isLoadingAISuggestions ? "Placeholder tagline" : viewModel.tagline)
                    .foregroundStyle(.secondary)
                    .captionStyle()
                    .redacted(reason: viewModel.isLoadingAISuggestions ? .placeholder : [])
                    .shimmering(active: viewModel.isLoadingAISuggestions)

                HStack(spacing: Layout.contentPadding) {
                    // Description
                    Text(viewModel.isLoadingAISuggestions ? "This is a placeholder description" : viewModel.description)
                        .fontWeight(.semibold)
                        .headlineStyle()
                        .multilineTextAlignment(.leading)
                        .redacted(reason: viewModel.isLoadingAISuggestions ? .placeholder : [])
                        .shimmering(active: viewModel.isLoadingAISuggestions)

                    Spacer()

                    // Simulate shop button
                    Text(Localization.shopNow)
                        .fontWeight(.semibold)
                        .captionStyle()
                        .padding(Layout.contentMargin)
                        .background(Color(uiColor: .systemGray6))
                        .cornerRadius(Layout.adButtonCornerRadius)
                }

                // Label "Suggested by AI"
                HStack {
                    HStack(spacing: 0) {
                        Image(uiImage: .sparklesImage)
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(Color(uiColor: .textSubtle))
                            .frame(width: Layout.sparkleIconSize * scale, height: Layout.sparkleIconSize * scale)

                        Text(Localization.suggestedByAI)
                            .subheadlineStyle()
                    }
                    Spacer()
                }
                .renderedIf(viewModel.isUsingAISuggestions)
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
                viewModel.didTapEditAd()
            }, label: {
                Text(Localization.editAd)
                    .fontWeight(.semibold)
                    .font(.body)
                    .foregroundColor(.accentColor)
            })
            .buttonStyle(.plain)
            .disabled(!viewModel.canEditAd)
            .redacted(reason: !viewModel.canEditAd ? .placeholder : [])
            .shimmering(active: !viewModel.canEditAd)
        }
        .environment(\.colorScheme, .light)
        .padding(Layout.contentPadding)
        .background(Color(light: .init(uiColor: .systemGray6),
                          dark: .init(uiColor: .tertiarySystemBackground)))
        .cornerRadius(Layout.cornerRadius)
        .padding(.vertical, Layout.contentPadding)
    }

    func detailView(title: String, content: String, isContentSingleLine: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action, label: {
            HStack {
                VStack(alignment: .leading, spacing: Layout.detailContentSpacing) {
                    Text(title)
                        .bodyStyle()
                    Text(content)
                        .secondaryBodyStyle()
                        .multilineTextAlignment(.leading)
                        .lineLimit(isContentSingleLine ? 1 : nil)
                }
                Spacer()
                Image(systemName: "chevron.forward")
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
    var supportForm: some View {
        NavigationView {
            SupportForm(isPresented: $isShowingSupport,
                        viewModel: SupportFormViewModel(sourceTag: Constants.supportTag))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.done) {
                        isShowingSupport = false
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
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
        static let maxWidth: CGFloat = 525
        static let sparkleIconSize: CGFloat = 24
    }

    enum Constants {
        static let backgroundViewColor = Color(light: .init(uiColor: .systemBackground),
                                               dark: .init(uiColor: .secondarySystemBackground))
        static let cellColor = Color(light: .init(uiColor: .systemBackground),
                                     dark: .init(uiColor: .tertiarySystemBackground))

        static let supportTag = "origin:blaze-native-campaign-creation"
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
        static let suggestedByAI = NSLocalizedString(
            "blazeCampaignCreationForm.suggestedByAI",
            value: "Suggested by AI",
            comment: "Suggested by AI title in the Blaze Campaign Creation Form."
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
        static let audience = NSLocalizedString(
            "blazeCampaignCreationForm.audience",
            value: "Audience",
            comment: "Section title on the Blaze campaign creation screen"
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
        static let adDestinationEmpty = NSLocalizedString(
            "blazeCampaignCreationForm.adDestination.empty",
            value: "Select destination URL",
            comment: "Content of the Ad destination field when the destination URL is empty on the Blaze campaign creation screen"
        )
        static let confirmDetails = NSLocalizedString(
            "blazeCampaignCreationForm.confirmDetails",
            value: "Confirm Details",
            comment: "Button to confirm ad details on the Blaze campaign creation screen"
        )

        enum AISuggestionsErrorAlert {
            static let fetchingAISuggestions = NSLocalizedString(
                "blazeCampaignCreationForm.aiSuggestionsErrorAlert.fetchingAISuggestions",
                value: "Failed to load suggestions for tagline and description",
                comment: "Error message indicating that loading suggestions for tagline and description failed"
            )
            static let cancel = NSLocalizedString(
                "blazeCampaignCreationForm.aiSuggestionsErrorAlert.cancel",
                value: "Cancel",
                comment: "Dismiss button on the error alert displayed on the Blaze campaign creation screen"
            )
            static let retry = NSLocalizedString(
                "blazeCampaignCreationForm.aiSuggestionsErrorAlert.retry",
                value: "Retry",
                comment: "Button on the error alert displayed on the Blaze campaign creation screen"
            )
        }

        enum NoImageErrorAlert {
            static let noImageFound = NSLocalizedString(
                "blazeCampaignCreationForm.noImageErrorAlert.noImageFound",
                value: "Please add an image for the Blaze campaign",
                comment: "Message asking to select an image for the Blaze campaign"
            )
            static let cancel = NSLocalizedString(
                "blazeCampaignCreationForm.noImageErrorAlert.cancel",
                value: "Cancel",
                comment: "Dismiss button on the alert asking to add an image for the Blaze campaign"
            )
            static let addImage = NSLocalizedString(
                "blazeCampaignCreationForm.noImageErrorAlert.addImage",
                value: "Add Image",
                comment: "Button on the alert to add an image for the Blaze campaign"
            )
        }

        enum NoDestinationURLAlert {
            static let noURLFound = NSLocalizedString(
                "blazeCampaignCreationForm.noDestinationURLAlert.noURLFound",
                value: "Please select a destination URL for the Blaze campaign",
                comment: "Message asking to select a destination URL for the Blaze campaign"
            )
            static let cancel = NSLocalizedString(
                "blazeCampaignCreationForm.noDestinationURLAlert.cancel",
                value: "Cancel",
                comment: "Dismiss button on the alert asking to select a destination URL for the Blaze campaign"
            )
            static let selectURL = NSLocalizedString(
                "blazeCampaignCreationForm.noDestinationURLAlert.selectURL",
                value: "Select URL",
                comment: "Button on the alert to select a destination URL for the Blaze campaign"
            )
        }

        static let help = NSLocalizedString(
            "blazeCampaignCreationForm.help",
            value: "Help",
            comment: "Button to contact support on the Blaze campaign form screen."
        )

        static let done = NSLocalizedString(
            "blazeCampaignCreationForm.done",
            value: "Done",
            comment: "Button to dismiss the support form from the Blaze campaign form screen."
        )

    }
}

struct BlazeCampaignCreationForm_Previews: PreviewProvider {
    static var previews: some View {
        BlazeCampaignCreationForm(viewModel: .init(siteID: 123, productID: 123, onCompletion: {}))
    }
}
