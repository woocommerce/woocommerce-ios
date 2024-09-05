import SwiftUI

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
            ForEach(viewModel.fetchedData, id: \.id) { item in
                HStack {
                    Text(item.title)
                    Spacer()
                    Image(uiImage: .checkmarkStyledImage)
                        .renderedIf(viewModel.selectedObjective == item)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if viewModel.selectedObjective == item {
                        viewModel.selectedObjective = nil
                    } else {
                        viewModel.selectedObjective = item
                    }
                }
            }
        }
        .listStyle(.grouped)
    }
}

private extension BlazeCampaignObjectivePickerView {
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
    }
}

#Preview {
    BlazeCampaignObjectivePickerView(viewModel: .init(siteID: 123, onSelection: { _ in }), onDismiss: {})
}
