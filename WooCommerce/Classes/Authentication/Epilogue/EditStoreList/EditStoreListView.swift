import SwiftUI

/// View to edit the items to be displayed on the store picker
///
struct EditStoreListView: View {
    @ObservedObject var viewModel: EditStoreListViewModel

    private let onDismiss: () -> Void

    init(viewModel: EditStoreListViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(viewModel.availableSites, id: \.siteID) { item in
                        SelectableItemRow(title: item.name,
                                          subtitle: item.url,
                                          selected: viewModel.isSelected(item),
                                          displayMode: .full,
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
            .listStyle(.plain)
            .navigationTitle("Visible Stores")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }

                    Button("Save") {
                        viewModel.didSaveChanges()
                    }
                    .disabled(viewModel.hasChanges == false)
                }
            }
        }
    }
}
