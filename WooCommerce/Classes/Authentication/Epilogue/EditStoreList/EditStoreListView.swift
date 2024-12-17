import SwiftUI

/// Hosting controller for `EditStoreListView`
///
final class EditStoreListViewController: UIHostingController<EditStoreListView> {
    init(viewModel: EditStoreListViewModel) {
        super.init(rootView: EditStoreListView(viewModel: viewModel))
        rootView.onDismiss = { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View to edit the items to be displayed on the store picker
///
struct EditStoreListView: View {
    @ObservedObject var viewModel: EditStoreListViewModel

    /// To be set externally in the hosting controller
    var onDismiss: () -> Void = {}

    init(viewModel: EditStoreListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(viewModel.availableSites, id: \.siteID) { item in
                        SelectableItemRow(title: item.name,
                                          subtitle: item.url,
                                          selected: viewModel.isSelected(item),
                                          displayMode: .compact,
                                          verticalSpacing: 0,
                                          selectionStyle: .checkcircle)
                        .listRowInsets(.zero)
                        .onTapGesture {
                            viewModel.toggleSelection(item)
                        }
                        .disabled(viewModel.isLastSelected(item))
                    }
                } footer: {
                    Text(Localization.listFooter)
                }
            }
            .listStyle(.grouped)
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButton) {
                        onDismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.saveButton) {
                        viewModel.didSaveChanges()
                    }
                    .disabled(viewModel.hasChanges == false)
                }
            }
        }
    }
}

private extension EditStoreListView {
    enum Localization {
        static let listFooter = NSLocalizedString(
            "editStoreListView.listFooter",
            value: "Stores that are not selected will be excluded from the store picker",
            comment: "Label at the end of the Edit Store List view"
        )
        static let cancelButton = NSLocalizedString(
            "editStoreListView.cancelButton",
            value: "Cancel",
            comment: "Button to dismiss the Edit Store List view"
        )
        static let saveButton = NSLocalizedString(
            "editStoreListView.saveButton",
            value: "Save",
            comment: "Button to save changes in the Edit Store List view"
        )
        static let title = NSLocalizedString(
            "editStoreListView.title",
            value: "Visible Stores",
            comment: "Title of the Edit Store List view"
        )
    }
}
