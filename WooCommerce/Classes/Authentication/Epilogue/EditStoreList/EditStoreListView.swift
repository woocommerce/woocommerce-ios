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
                if let site = viewModel.currentlySelectedSite {
                    Section {
                        VStack(alignment: .leading) {
                            Text(site.name)
                                .bodyStyle()
                            Text(site.url)
                                .footnoteStyle()
                        }
                        .multilineTextAlignment(.leading)
                    } header: {
                        Text(Localization.currentStoreHeader)
                    } footer: {
                        Text(Localization.currentStoreFooter)
                    }
                }

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
                } header: {
                    Text(Localization.otherStoresHeader)
                } footer: {
                    Text(Localization.otherStoresFooter)
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
                    if viewModel.isUpdatingNotificationSettings {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Button(Localization.saveButton) {
                            Task {
                                await viewModel.saveChanges()
                            }
                        }
                        .disabled(viewModel.hasChanges == false)
                    }
                }
            }
            .alert(Localization.errorUpdatingNotificationSettings, isPresented: $viewModel.shouldShowErrorAlert, actions: {
                Button(Localization.cancelButton) {}
                Button(Localization.retryButton) {
                    Task {
                        await viewModel.saveChanges()
                    }
                }
            })
        }
    }
}

private extension EditStoreListView {
    enum Localization {
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
        static let currentStoreHeader = NSLocalizedString(
            "editStoreListView.currentStoreHeader",
            value: "Current store",
            comment: "Header of the Current Store section of the the Edit Store List view"
        )
        static let currentStoreFooter = NSLocalizedString(
            "editStoreListView.currentStoreFooter",
            value: "Please switch to another store before hiding this store",
            comment: "Footer of the Current Store section of the the Edit Store List view"
        )
        static let otherStoresHeader = NSLocalizedString(
            "editStoreListView.otherStoresHeader",
            value: "Other stores",
            comment: "Header of the Other Stores section on the Edit Store List view"
        )
        static let otherStoresFooter = NSLocalizedString(
            "editStoreListView.unselectedStoresNote",
            value: "Unselected stores will be excluded from the store picker and won't receive push notifications for new orders or product.",
            comment: "Footer of the Other Stores section on the Edit Store List view"
        )
        static let retryButton = NSLocalizedString(
            "editStoreListView.retryButton",
            value: "Retry",
            comment: "Button to retry saving changes in the Edit Store List view"
        )
        static let errorUpdatingNotificationSettings = NSLocalizedString(
            "editStoreListView.errorUpdatingNotificationSettings",
            value: "There was an error when updating notification settings. Please try again.",
            comment: "Error message when updating notification settings fails when saving the store list for the store picker"
        )
    }
}
