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
                    Text("Stores that are not selected will be excluded from the store picker")
                }
            }
            .listStyle(.grouped)
            .navigationTitle("Visible Stores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.didSaveChanges()
                    }
                    .disabled(viewModel.hasChanges == false)
                }
            }
        }
    }
}
