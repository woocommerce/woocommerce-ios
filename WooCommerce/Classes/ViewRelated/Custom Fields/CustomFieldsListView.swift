import SwiftUI

struct CustomFieldsListView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var viewModel: CustomFieldsListViewModel

    let isEditable: Bool
    let onBackButtonTapped: () -> Void

    init(isEditable: Bool,
         viewModel: CustomFieldsListViewModel,
         onBackButtonTapped: @escaping () -> Void) {
        self.isEditable = isEditable
        self.viewModel = viewModel
        self.onBackButtonTapped = onBackButtonTapped
    }

    var body: some View {
        NavigationStack {
            List(viewModel.combinedList) { customField in
                if isEditable {
                    NavigationLink(destination: CustomFieldEditorView(key: customField.key, value: customField.value, onSave: { updatedKey, updatedValue in
                        viewModel.saveField(key: updatedKey, value: updatedValue, fieldId: customField.fieldId)
                    })) {
                        CustomFieldRow(isEditable: true,
                                       title: customField.key,
                                       content: customField.value.removedHTMLTags,
                                       contentURL: nil)
                    }
                } else {
                    CustomFieldRow(isEditable: false,
                                   title: customField.key,
                                   content: customField.value.removedHTMLTags,
                                   contentURL: nil)
                }
            }
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        onBackButtonTapped()
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Image(systemName: "chevron.backward")
                    })
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditable {
                        HStack {
                            Button {
                                // todo-13493: add save handling
                            } label: {
                                Text("Save") // todo-13493: set String to be translatable
                            }
                            .disabled(!viewModel.hasChanges)
                            Button(action: {
                                // todo-13493: add addition handling
                            }, label: {
                                Image(systemName: "plus")
                                    .renderingMode(.template)
                            })
                        }
                    }
                }
            }
        }
        .wooNavigationBarStyle()
        .navigationViewStyle(.stack)
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
extension CustomFieldsListView {
    enum Localization {
        static let title = NSLocalizedString("Custom Fields", comment: "Title for the order custom fields list")
    }
}

private extension CustomFieldRow {
    enum Constants {
        static let spacing: CGFloat = 8
        static let vStackPadding: CGFloat = 16
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
                ]),
            onBackButtonTapped: { }
            )
    }
}

#endif
