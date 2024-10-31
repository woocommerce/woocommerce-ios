import Combine
import SwiftUI
import protocol WooFoundation.Analytics

final class CustomFieldsListHostingController: UIHostingController<CustomFieldsListView> {
    private let viewModel: CustomFieldsListViewModel
    private let analytics: Analytics
    private var subscriptions: Set<AnyCancellable> = []

    init(isEditable: Bool, viewModel: CustomFieldsListViewModel, analytics: Analytics = ServiceLocator.analytics) {
        self.viewModel = viewModel
        self.analytics = analytics
        super.init(rootView: CustomFieldsListView(isEditable: isEditable,
                                                  viewModel: viewModel)
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        analytics.track(
            event: .CustomFields.customFieldsListLoaded(
                type: viewModel.customFieldsType.analyticsValue,
                fieldsCount: viewModel.originalCustomFieldsCount,
                fieldsSize: viewModel.originalCustomFieldsSize,
                has_json_fields: false) // TODO: #14273 has_json_fields logic
        )

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

extension CustomFieldsListHostingController {
    override func shouldPopOnBackButton() -> Bool {
        if viewModel.hasChanges {
            presentBackNavigationActionSheet()
            return false
        }
        return true
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }
}

private extension CustomFieldsListHostingController {
    func configureNavigation() {
        title = Localization.title
        navigationItem.rightBarButtonItems = [saveCustomFieldButtonItem, addCustomFieldButtonItem]
    }

    @objc func openAddCustomFieldScreen() {
        viewModel.trackAddCustomFieldTapped()
        viewModel.isAddingNewField = true
    }

    @objc func saveCustomField() {
        viewModel.trackSaveCustomFieldTapped()
        Task {
            await viewModel.saveChanges()
        }
    }

    func observeStateChange() {
        viewModel.$hasChanges
            .sink { [weak self] hasChanges in
                self?.saveCustomFieldButtonItem.isEnabled = hasChanges
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

    func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
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
        GeometryReader { geometry in
            VStack(spacing: .zero) {
                CustomFieldsListTopBanner(width: geometry.size.width)
                    .onDismiss { viewModel.dismissTopBanner() }
                    .fixedSize(horizontal: false, vertical: true) // Forces view to recalculate it's height
                    .renderedIf(viewModel.shouldShowTopBanner)

                List(viewModel.combinedList) { customField in
                    Button(action: {
                        viewModel.selectedCustomField = customField
                        viewModel.trackCustomFieldTapped()
                    }) {
                        CustomFieldRow(isEditable: isEditable,
                                    title: customField.key,
                                    content: customField.value.removedHTMLTags,
                                    contentURL: nil)
                    }
                }
                .listStyle(.plain)
            }
            .sheet(item: $viewModel.selectedCustomField) { customField in
                /// When editing a newly added and unsaved custom field (identified by it having nil `fieldId`), provide disallowed keys.
                let disallowedKeys = customField.fieldId == nil ? viewModel.disallowedKeysForCreation : []

                buildCustomFieldEditorView(customField: customField,
                                           disallowedKeys: disallowedKeys)
            }
            .sheet(isPresented: $viewModel.isAddingNewField) {
                buildCustomFieldEditorView(customField: nil, disallowedKeys: viewModel.disallowedKeysForCreation)
            }
            .notice($viewModel.notice)
        }
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

// MARK: - Helpers
//
private extension CustomFieldsListView {
    /// Builds the Custom Field Editor View. There are two possible modes for the editor:
    /// - Creating a new custom field: the Key and Value fields will be empty, and deleting option should be hidden.
    /// - Editing an existing custom field: the Key and Value fields will use the values from the provided `customField`
    ///
    /// Parameters:
    /// - `customField`: Provide one when editing an existing field, otherwise (i.e: when creating a new field) keep it nil.
    /// - `disallowedKeys`: List of String that can't be used when editing a custom field key.
    func buildCustomFieldEditorView(customField: CustomFieldsListViewModel.CustomFieldUI?,
                                    disallowedKeys: [String] = []) -> some View {
        NavigationView {
            CustomFieldEditorView(viewModel: CustomFieldEditorViewModel(
                key: customField?.key ?? "",
                value: customField?.value ?? "",
                disallowedKeys: disallowedKeys,
                onSave: { updatedKey, updatedValue in
                    viewModel.saveField(
                        key: updatedKey,
                        value: updatedValue,
                        fieldId: customField?.fieldId
                    )
                },
                onDelete: customField != nil ? {
                    // Only provide delete callback when editing existing field
                    viewModel.deleteField(customField!)
                } : nil
            ))
        }
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
            value: "Add a new custom field to the list",
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
        static let saveSuccessTitle = NSLocalizedString(
            "customFieldsListHostingController.saveSuccessTitle",
            value: "Changes saved",
            comment: "Title for the success message when saving changes"
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
