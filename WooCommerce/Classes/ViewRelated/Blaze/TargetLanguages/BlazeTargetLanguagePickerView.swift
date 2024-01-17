import SwiftUI
import struct Yosemite.BlazeTargetLanguage

/// View for picking target languages for a Blaze campaign
struct BlazeTargetLanguagePickerView: View {

    @ObservedObject private var viewModel: BlazeTargetLanguagePickerViewModel

    private let onDismiss: () -> Void

    init(viewModel: BlazeTargetLanguagePickerViewModel,
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
                case .result(let languages):
                    MultiSelectionList(allOptionsTitle: Localization.allTitle,
                                       contents: languages,
                                       contentKeyPath: \.name,
                                       selectedItems: $viewModel.selectedLanguages,
                                       onQueryChanged: { query in
                        viewModel.searchQuery = query
                    })
                case .error:
                    ErrorStateView(title: Localization.errorMessage,
                                   image: .errorImage,
                                   actionTitle: Localization.tryAgain,
                                   actionHandler: {
                        Task {
                            await viewModel.syncLanguages()
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
            await viewModel.syncLanguages()
        }
        .navigationViewStyle(.stack)
    }
}

private extension BlazeTargetLanguagePickerView {
    enum Localization {
        static let title = NSLocalizedString(
            "blazeTargetLanguagePickerView.title",
            value: "Languages",
            comment: "Title of the target language picker view for Blaze campaign creation"
        )
        static let allTitle = NSLocalizedString(
            "blazeTargetLanguagePickerView.allTitle",
            value: "All languages",
            comment: "Title of the row to select all target languages for Blaze campaign creation"
        )
        static let cancelButtonTitle = NSLocalizedString(
            "blazeTargetLanguagePickerView.cancel",
            value: "Cancel",
            comment: "Button to dismiss the target language picker for campaign creation"
        )
        static let saveButtonTitle = NSLocalizedString(
            "blazeTargetLanguagePickerView.save",
            value: "Save",
            comment: "Button to save the selections on the target language picker for campaign creation"
        )
        static let errorMessage = NSLocalizedString(
            "blazeTargetLanguagePickerView.errorMessage",
            value: "Error syncing target languages. Please try again.",
            comment: "Error message when data syncing fails on the target language picker for campaign creation"
        )
        static let tryAgain = NSLocalizedString(
            "blazeTargetLanguagePickerView.tryAgain",
            value: "Try Again",
            comment: "Button to retry syncing data on the target language picker for campaign creation"
        )
    }
}

struct BlazeTargetLanguagePickerView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeTargetLanguagePickerView(viewModel: BlazeTargetLanguagePickerViewModel(siteID: 123, selectedLanguages: nil) { _ in }, onDismiss: {})
    }
}
