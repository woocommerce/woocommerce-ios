import SwiftUI
import struct Yosemite.BlazeCampaignObjective

/// View for picking campaign objective for Blaze campaign creation
///
struct BlazeCampaignObjectivePickerView: View {
    @ObservedObject private var viewModel: BlazeCampaignObjectivePickerViewModel
    @ScaledMetric private var scale = 1

    private let onDismiss: () -> Void

    init(viewModel: BlazeCampaignObjectivePickerViewModel,
         onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.fetchedData.isNotEmpty {
                    optionList
                } else if viewModel.isSyncingData {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                } else if viewModel.syncError != nil {
                    ErrorStateView(title: Localization.errorMessage,
                                   image: .errorImage,
                                   actionTitle: Localization.tryAgain,
                                   actionHandler: {
                        Task {
                            await viewModel.syncData()
                        }
                    })
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButtonTitle, action: onDismiss)
                }
            }
            .safeAreaInset(edge: .bottom) {
                footerView
            }
        }
        .task {
            await viewModel.syncData()
        }
    }
}

private extension BlazeCampaignObjectivePickerView {
    var optionList: some View {
        ScrollView {
            ForEach(viewModel.fetchedData, id: \.id) { item in
                Button {
                    viewModel.selectedObjective = item
                } label: {
                    VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                        HStack(spacing: Layout.contentMargin) {
                            Image(uiImage: isItemSelected(item) ? .checkCircleImage.withRenderingMode(.alwaysTemplate) : .checkEmptyCircleImage)
                                .resizable()
                                .frame(width: Layout.radioButtonSize * scale,
                                       height: Layout.radioButtonSize * scale)
                                .if(isItemSelected(item)) { view in
                                    view.foregroundStyle(Color.accentColor)
                                }
                            Text(item.title)
                                .headlineStyle()
                            Spacer()
                        }

                        HStack(spacing: Layout.contentMargin) {
                            Spacer()
                                .frame(width: Layout.radioButtonSize * scale,
                                       height: Layout.radioButtonSize * scale)

                            VStack(alignment: .leading, spacing: Layout.contentMargin) {
                                Text(item.description)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.primary)
                                // Good for text
                                (Text(Localization.goodFor).bold() + Text(" ") + Text(item.suitableForDescription))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.primary)
                                    .renderedIf(isItemSelected(item))
                            }
                            Spacer()
                        }
                    }
                    .multilineTextAlignment(.leading)
                    .padding(Layout.contentMargin)
                    .background(
                        (isItemSelected(item) ? Layout.selectedBackgroundColor : Color(uiColor: .listForeground(modal: false)))
                        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: Layout.cornerRadius)
                            .stroke(Color(uiColor: isItemSelected(item) ? .accent : .separator),
                                    lineWidth: Layout.strokeWidth)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityHint(isItemSelected(item) ? Localization.selected : Localization.unselected)
            }
            .padding(Layout.contentMargin)
        }
    }

    var footerView: some View {
        VStack(alignment: .center, spacing: Layout.contentMargin) {
            Divider()
            // Toggle to save the selection
            Toggle(Localization.saveSelection, isOn: $viewModel.saveSelectionForFutureCampaigns)
                .padding(.horizontal, Layout.contentMargin)

            // CTA to confirm the selection
            Button(Localization.saveButtonTitle) {
                viewModel.confirmSelection()
                onDismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.shouldDisableSaveButton)
            .padding([.horizontal, .bottom], Layout.contentMargin)
        }
        .background(Color(.systemBackground))
    }

    func isItemSelected(_ item: BlazeCampaignObjective) -> Bool {
        item == viewModel.selectedObjective
    }
}

private extension BlazeCampaignObjectivePickerView {
    enum Layout {
        static let contentSpacing: CGFloat = 8
        static let contentMargin: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let strokeWidth: CGFloat = 1
        static let radioButtonSize: CGFloat = 24
        static let selectedBackgroundColor = Color(
            light: .withColorStudio(name: .wooCommercePurple, shade: .shade0),
            dark: .withColorStudio(name: .wooCommercePurple, shade: .shade80)
        )
    }

    enum Localization {
        static let title = NSLocalizedString(
            "blazeCampaignObjectivePickerView.title",
            value: "Campaign objective",
            comment: "Title of the campaign objective picker view for Blaze campaign creation"
        )
        static let message = NSLocalizedString(
            "blazeCampaignObjectivePickerView.message",
            value: "Choose campaign objective",
            comment: "Message on the campaign objective picker view for Blaze campaign creation"
        )
        static let cancelButtonTitle = NSLocalizedString(
            "blazeCampaignObjectivePickerView.cancel",
            value: "Cancel",
            comment: "Button to dismiss the campaign objective picker for Blaze campaign creation"
        )
        static let saveButtonTitle = NSLocalizedString(
            "blazeCampaignObjectivePickerView.save",
            value: "Save",
            comment: "Button to save the selection on the campaign objective picker for Blaze campaign creation"
        )
        static let errorMessage = NSLocalizedString(
            "blazeCampaignObjectivePickerView.errorMessage",
            value: "Error syncing campaign objectives. Please try again.",
            comment: "Error message when data syncing fails on the campaign objective picker for Blaze campaign creation"
        )
        static let tryAgain = NSLocalizedString(
            "blazeCampaignObjectivePickerView.tryAgain",
            value: "Try Again",
            comment: "Button to retry syncing data on the campaign objective picker for Blaze campaign creation"
        )
        static let goodFor = NSLocalizedString(
            "blazeCampaignObjectivePickerView.goodFor",
            value: "Good for:",
            comment: "Title for the explanation of a Blaze campaign objective."
        )
        static let saveSelection = NSLocalizedString(
            "blazeCampaignObjectivePickerView.saveSelection",
            value: "Save my selection for future campaigns",
            comment: "Toggle to save the selection of a Blaze campaign objective for future campaigns."
        )
        static let selected = NSLocalizedString(
            "blazeCampaignObjectivePickerView.accessibilityHintSelected",
            value: "Selected",
            comment: "Accessibility hint that an option is being selected on the campaign objective picker for Blaze campaign creation."
        )
        static let unselected = NSLocalizedString(
            "blazeCampaignObjectivePickerView.accessibilityHintUnselected",
            value: "Unselected",
            comment: "Accessibility hint that an option is being selected on the campaign objective picker for Blaze campaign creation."
        )
    }
}

#Preview {
    BlazeCampaignObjectivePickerView(viewModel: .init(siteID: 123, onSelection: { _ in }), onDismiss: {})
}
