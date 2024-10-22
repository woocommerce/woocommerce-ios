import Combine
import SwiftUI

final class CustomFieldsListHostingController: UIHostingController<CustomFieldsListView> {
    private let viewModel: CustomFieldsListViewModel
    private var subscriptions: Set<AnyCancellable> = []

    init(isEditable: Bool, viewModel: CustomFieldsListViewModel) {
        self.viewModel = viewModel
        super.init(rootView: CustomFieldsListView(isEditable: isEditable,
                                                  viewModel: viewModel)
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        observeStateChange()
    }

    /// Create a `UIBarButtonItem` to be used as the add custom field button on the top-right.
    ///
    private lazy var addCustomFieldButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(image: .plusImage,
                style: .plain,
                target: self,
                action: #selector(openAddCustomFieldScreen))
        button.accessibilityTraits = .button
        button.accessibilityLabel = Localization.accessibilityLabelAddCustomField
        button.accessibilityHint = Localization.accessibilityHintAddCustomField
        button.accessibilityIdentifier = "add-custom-field-button"

        return button
    }()

    /// Create a `UIBarButtonItem` to be used as the save custom field button on the top-right.
    ///
    private lazy var saveCustomFieldButtonItem =
        UIBarButtonItem(title: Localization.save,
                        style: .plain,
                        target: self,
                        action: #selector(saveCustomField))

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension CustomFieldsListHostingController {
    func configureNavigation() {
        title = Localization.title
        navigationItem.rightBarButtonItems = [saveCustomFieldButtonItem, addCustomFieldButtonItem]
    }

    @objc func openAddCustomFieldScreen() {
        viewModel.isAddingNewField = true
    }

    @objc func saveCustomField() {
        Task {
            await viewModel.saveChanges()
        }
    }

    func observeStateChange() {
        viewModel.$pendingChanges
            .sink { [weak self] pendingChanges in
                self?.saveCustomFieldButtonItem.isEnabled = pendingChanges.hasChanges
            }
            .store(in: &subscriptions)

        viewModel.$isSavingChanges
            .sink { [weak self] isSavingChanges in
                if isSavingChanges {
                    self?.displayInProgressController()
                } else {
                    self?.dismissInProgressController()
                }
            }
            .store(in: &subscriptions)
    }

    func displayInProgressController() {
        let inProgressController = InProgressViewController(
            viewProperties: InProgressViewProperties(
                title: Localization.inProgressTitle,
                message: Localization.inProgressMessage
            )
        )
        inProgressController.modalPresentationStyle = .overFullScreen
        present(inProgressController, animated: true)
    }

    func dismissInProgressController() {
        dismiss(animated: true)
    }
}

struct CustomFieldsListView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var viewModel: CustomFieldsListViewModel

    let isEditable: Bool

    init(isEditable: Bool,
         viewModel: CustomFieldsListViewModel) {
        self.isEditable = isEditable
        self.viewModel = viewModel
    }

    var body: some View {
        List(viewModel.combinedList) { customField in
            Button(action: { viewModel.selectedCustomField = customField }) {
                CustomFieldRow(isEditable: isEditable,
                               title: customField.key,
                               content: customField.value.removedHTMLTags,
                               contentURL: nil)
            }
        }
        .listStyle(.plain)
        .sheet(item: $viewModel.selectedCustomField, content: { customField in
            NavigationView {
                CustomFieldEditorView(key: customField.key,
                                      value: customField.value,
                                      onSave: { updatedKey, updatedValue in
                                          viewModel.saveField(key: updatedKey, value: updatedValue, fieldId: customField.fieldId)
                                      },
                                      onDelete: { viewModel.deleteField(customField) })
            }
        })
        .sheet(isPresented: $viewModel.isAddingNewField) {
            NavigationView {
                CustomFieldEditorView(key: "",
                                      value: "",
                                      isCreatingNewField: true,
                                      onSave: { updatedKey, updatedValue in
                                          viewModel.saveField(key: updatedKey, value: updatedValue, fieldId: nil)
                                      })
            }
        }
        .notice($viewModel.notice)
    }
}

private struct CustomFieldRow: View {
    /// Determines if the row is editable
    let isEditable: Bool

    /// Custom Field title
    ///
    let title: String

    /// Custom Field content
    ///
    let content: String

    /// Optional URL to link the content
    ///
    let contentURL: URL?

    /// URL to display in `SafariSheet` in app
    ///
    @State private var displayedURL: URL?

    /// Action to open URL with system handler
    ///
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack {
            VStack(alignment: .leading,
                   spacing: Constants.spacing) {
                Text(title)

                if let url = contentURL { // Display content as a link if URL is provided
                    Text(content)
                        .font(.footnote)
                        .foregroundColor(Color(.textLink))
                        .safariSheet(url: $displayedURL)
                        .onTapGesture {
                            switch url.scheme {
                            case "http", "https":
                                displayedURL = url // Open in `SafariSheet` in app
                            default:
                                openURL(url) // Open in associated app for URL scheme
                            }
                        }
                        .lineLimit(isEditable ? 2 : nil)
                } else { // Display content as plain text
                    Text(content)
                        .footnoteStyle()
                        .lineLimit(isEditable ? 2 : nil)
                }
            }
        }
        .padding(Constants.hStackPadding)
        .frame(minHeight: Constants.height)
    }
}


// MARK: - Constants
//
extension CustomFieldsListHostingController {
    enum Localization {
        static let title = NSLocalizedString(
            "customFieldsListHostingController.title",
            value: "Custom Fields",
            comment: "Title for the order custom fields list")

        static let accessibilityLabelAddCustomField = NSLocalizedString(
            "customFieldsListHostingController.accessibilityLabelAddCustomField",
            value: "Add custom field",
            comment: "Accessibility label for the Add Custom Field button")

        static let accessibilityHintAddCustomField = NSLocalizedString(
            "customFieldsListHostingController.accessibilityHintAddCustomField",
            value: "Add a new Custom FIeld to the list",
            comment: "VoiceOver accessibility hint, informing the user the button can be used to add custom field.")

        static let save = NSLocalizedString(
            "customFieldsListHostingController.save",
            value: "Save",
            comment: "Button to save the changes on Custom Fields list")
        static let deleteNoticeTitle = NSLocalizedString(
            "customFieldsListHostingController.deleteNoticeTitle",
            value: "Custom field deleted",
             comment: "Title for the notice when a custom field is deleted"
             )
        static let deleteNoticeUndo = NSLocalizedString(
            "customFieldsListHostingController.deleteNoticeUndo",
            value: "Undo",
            comment: "Action to undo the deletion of a custom field"
        )
        static let inProgressTitle = NSLocalizedString(
            "customFieldsListHostingController.inProgressTitle",
            value: "Saving...",
            comment: "Title for the in progress view shown when saving changes"
        )
        static let inProgressMessage = NSLocalizedString(
            "customFieldsListHostingController.inProgressMessage",
            value: "Please wait while we save your changes",
            comment: "Message for the in progress view shown when saving changes"
        )
        static let saveErrorTitle = NSLocalizedString(
            "customFieldsListHostingController.saveErrorTitle",
            value: "Error saving changes",
            comment: "Title for the error message when saving changes"
        )
        static let saveErrorMessage = NSLocalizedString(
            "customFieldsListHostingController.saveErrorMessage",
            value: "There was an error saving your changes. Please try again.",
            comment: "Message for the error message when saving changes"
        )
    }
}

private extension CustomFieldRow {
    enum Constants {
        static let spacing: CGFloat = 8
        static let hStackPadding: CGFloat = 10
        static let height: CGFloat = 64
    }
}

#if DEBUG

struct OrderCustomFieldsDetails_Previews: PreviewProvider {
    static var previews: some View {
        CustomFieldsListView(
            isEditable: true,
            viewModel: CustomFieldsListViewModel(
                customFields: [
                    CustomFieldViewModel(id: 0, title: "First Title", content: "First Content"),
                    CustomFieldViewModel(id: 1, title: "Second Title", content: "Second Content", contentURL: URL(string: "https://woocommerce.com/"))
                ],
                siteID: 0,
                parentItemID: 0,
                customFieldType: .order
                ))
    }
}

#endif
