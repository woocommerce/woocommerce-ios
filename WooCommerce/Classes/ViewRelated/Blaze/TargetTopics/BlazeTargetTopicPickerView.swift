import SwiftUI
import struct Yosemite.BlazeTargetTopic

/// View for picking target devices for a Blaze campaign
struct BlazeTargetTopicPickerView: View {
    @ObservedObject private var viewModel: BlazeTargetTopicPickerViewModel

    private let onDismiss: () -> Void

    init(viewModel: BlazeTargetTopicPickerViewModel,
         onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationView {
            Group {
                switch viewModel.syncState {
                case .syncing:
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                case .result(let topics):
                    MultiSelectionList(headerMessage: Localization.message,
                                       allOptionsTitle: Localization.allTitle,
                                       contents: topics,
                                       contentKeyPath: \.name,
                                       selectedItems: $viewModel.selectedTopics,
                                       onQueryChanged: { query in
                        viewModel.searchQuery = query
                    })
                case .error:
                    ErrorStateView(title: Localization.errorMessage,
                                   image: .errorImage,
                                   actionTitle: Localization.tryAgain,
                                   actionHandler: {
                        Task {
                            await viewModel.syncTopics()
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
        .navigationViewStyle(.stack)
        .task {
            await viewModel.syncTopics()
        }
    }
}

private extension BlazeTargetTopicPickerView {
    enum Localization {
        static let title = NSLocalizedString(
            "blazeTargetTopicPickerView.title",
            value: "Interests",
            comment: "Title of the target topic picker view for Blaze campaign creation"
        )
        static let message = NSLocalizedString(
            "blazeTargetTopicPickerView.message",
            value: "Choose relevant topics",
            comment: "Message on the target topic picker view for Blaze campaign creation"
        )
        static let allTitle = NSLocalizedString(
            "blazeTargetTopicPickerView.allTitle",
            value: "All topics",
            comment: "Title of the row to select all target topics for Blaze campaign creation"
        )
        static let cancelButtonTitle = NSLocalizedString(
            "blazeTargetTopicPickerView.cancel",
            value: "Cancel",
            comment: "Button to dismiss the target topic picker for campaign creation"
        )
        static let saveButtonTitle = NSLocalizedString(
            "blazeTargetTopicPickerView.save",
            value: "Save",
            comment: "Button to save the selections on the target topic picker for campaign creation"
        )
        static let errorMessage = NSLocalizedString(
            "blazeTargetTopicPickerView.errorMessage",
            value: "Error syncing target topics. Please try again.",
            comment: "Error message when data syncing fails on the target topic picker for campaign creation"
        )
        static let tryAgain = NSLocalizedString(
            "blazeTargetTopicPickerView.tryAgain",
            value: "Try Again",
            comment: "Button to retry syncing data on the target topic picker for campaign creation"
        )
    }
}

#Preview {
    BlazeTargetTopicPickerView(viewModel: .init(siteID: 123, onSelection: { _ in }), onDismiss: {})
}
