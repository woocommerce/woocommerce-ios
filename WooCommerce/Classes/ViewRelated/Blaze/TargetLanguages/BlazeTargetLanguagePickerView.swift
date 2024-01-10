import SwiftUI
import struct Yosemite.BlazeTargetLanguage

/// View for picking target languages for a Blaze campaign
struct BlazeTargetLanguagePickerView: View {

    @ObservedObject private var viewModel: BlazeTargetLanguagePickerViewModel
    @State private var selectedLanguages: Set<BlazeTargetLanguage>?

    private let onDismiss: () -> Void

    init(viewModel: BlazeTargetLanguagePickerViewModel,
         selectedLanguages: Set<BlazeTargetLanguage>?,
         onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.selectedLanguages = selectedLanguages
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationView {
            Group {
                MultiSelectionList(allOptionsTitle: Localization.allTitle,
                                   contents: viewModel.languages,
                                   contentKeyPath: \.name,
                                   selectedItems: $selectedLanguages,
                                   onQueryChanged: { query in
                    viewModel.searchQuery = query
                })
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButtonTitle, action: onDismiss)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.saveButtonTitle) {
                        viewModel.confirmSelection(selectedLanguages)
                        onDismiss()
                    }
                    .disabled(selectedLanguages?.isEmpty == true)
                }
            }
            .task {
                await viewModel.syncLanguages()
            }
        }
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
    }
}

struct BlazeTargetLanguagePickerView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeTargetLanguagePickerView(viewModel: BlazeTargetLanguagePickerViewModel(siteID: 123) { _ in }, selectedLanguages: [], onDismiss: {})
    }
}
