import SwiftUI

/// View for searching and selecting target locations for a Blaze campaign.
struct BlazeTargetLocationPickerView: View {

    @ObservedObject private var viewModel: BlazeTargetLocationPickerViewModel

    private let onDismiss: () -> Void

    init(viewModel: BlazeTargetLocationPickerViewModel,
         onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationView {
            BlazeTargetLocationSearchView(viewModel: viewModel)
                .searchable(text: $viewModel.searchQuery,
                            placement: .navigationBarDrawer(displayMode: .always),
                            prompt: Localization.searchPrompt)
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
    }
}

private extension BlazeTargetLocationPickerView {
    enum Localization {
        static let title = NSLocalizedString(
            "blazeTargetLocationPickerView.title",
            value: "Location",
            comment: "Title of the target language picker view for Blaze campaign creation"
        )
        static let cancelButtonTitle = NSLocalizedString(
            "blazeTargetLocationPickerView.cancel",
            value: "Cancel",
            comment: "Button to dismiss the target location picker for campaign creation"
        )
        static let saveButtonTitle = NSLocalizedString(
            "blazeTargetLocationPickerView.save",
            value: "Save",
            comment: "Button to save the selections on the target location picker for campaign creation"
        )
        static let searchPrompt = NSLocalizedString(
            "blazeTargetLocationPickerView.searchPrompt",
            value: "Search for locations",
            comment: "Placeholder on the search bar of the target location picker for campaign creation"
        )
    }
}

#Preview {
    BlazeTargetLocationPickerView(viewModel: .init(siteID: 123) { _ in }) {}
}
