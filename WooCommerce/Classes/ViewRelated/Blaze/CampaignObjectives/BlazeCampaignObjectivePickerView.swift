import SwiftUI
import struct Yosemite.BlazeCampaignObjective

/// View for picking campaign objective for Blaze campaign creation
///
struct BlazeCampaignObjectivePickerView: View {
    @ObservedObject private var viewModel: BlazeCampaignObjectivePickerViewModel

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
                } else if let error = viewModel.syncError {
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
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.saveButtonTitle) {
                        viewModel.confirmSelection()
                        onDismiss()
                    }
                    .disabled(viewModel.shouldDisableSaveButton)
                }
            }
        }
        .task {
            await viewModel.syncData()
        }
    }
}

private extension BlazeCampaignObjectivePickerView {
    var optionList: some View {
        List {
            Section {
                ForEach(viewModel.fetchedData, id: \.id) { item in
                    HStack(alignment: .center, spacing: Layout.padding) {
                        Image(uiImage: isItemSelected(item) ? .checkCircleImage.withRenderingMode(.alwaysTemplate) : .checkEmptyCircleImage)
                            .if(isItemSelected(item)) { view in
                                view.foregroundStyle(Color.accentColor)
                            }
                        Text(item.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .multilineTextAlignment(.leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedObjective = item
                    }
                }
            } footer: {
                if let item = viewModel.selectedObjective {
                    VStack(alignment: .leading) {
                        Text(item.title)
                            .headlineStyle()
                        VStack(alignment: .leading) {
                            Text(item.description)
                                .secondaryBodyStyle()
                            Text(Localization.goodFor)
                                .bodyStyle()
                                .padding(.top, Layout.padding)
                            Text(item.suitableForDescription)
                                .secondaryBodyStyle()
                        }
                    }
                    .padding(.top, Layout.padding)
                }
            }
        }
        .listStyle(.grouped)
    }

    func isItemSelected(_ item: BlazeCampaignObjective) -> Bool{
        item == viewModel.selectedObjective
    }
}

private extension BlazeCampaignObjectivePickerView {
    enum Layout {
        static let padding: CGFloat = 8
        static let explanationPadding: CGFloat = 16
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
            comment: "Button to dismiss the campaign objective picker for campaign creation"
        )
        static let saveButtonTitle = NSLocalizedString(
            "blazeCampaignObjectivePickerView.save",
            value: "Save",
            comment: "Button to save the selection on the campaign objective picker for campaign creation"
        )
        static let errorMessage = NSLocalizedString(
            "blazeCampaignObjectivePickerView.errorMessage",
            value: "Error syncing campaign objectives. Please try again.",
            comment: "Error message when data syncing fails on the campaign objective picker for campaign creation"
        )
        static let tryAgain = NSLocalizedString(
            "blazeCampaignObjectivePickerView.tryAgain",
            value: "Try Again",
            comment: "Button to retry syncing data on the campaign objective picker for campaign creation"
        )
        static let goodFor = NSLocalizedString(
            "blazeCampaignObjectivePickerView.goodFor",
            value: "Good for:",
            comment: "Title for the explanation of a Blaze campaign objective."
        )
    }
}

#Preview {
    BlazeCampaignObjectivePickerView(viewModel: .init(siteID: 123, onSelection: { _ in }), onDismiss: {})
}
