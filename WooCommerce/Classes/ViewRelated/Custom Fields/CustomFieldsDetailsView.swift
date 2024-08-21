import SwiftUI

struct CustomFieldsDetailsView: View {
    @Environment(\.presentationMode) var presentationMode

    let isEditable: Bool
    let customFields: [CustomFieldsViewModel]

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(customFields) { customField in
                            CustomFieldRow(isEditable: isEditable,
                                           title: customField.title,
                                           content: customField.content,
                                           contentURL: customField.contentURL)

                            Divider()
                                .padding(.leading)
                        }
                    }
                    .padding(.horizontal, insets: geometry.safeAreaInsets)
                    .background(Color(.listForeground(modal: false)))
                }
                .background(Color(.listBackground))
                .ignoresSafeArea(edges: .horizontal)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }, label: {
                            Image(uiImage: .closeButton)
                        })
                    }
                }
                .navigationTitle(Localization.title)
                .navigationBarTitleDisplayMode(.inline)
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
                        .lineLimit(isEditable ? 3 : nil)
                } else { // Display content as plain text
                    Text(content)
                        .footnoteStyle()
                        .lineLimit(isEditable ? 3 : nil)
                }
            }.padding([.leading, .trailing], Constants.vStackPadding)

            Spacer()

            if isEditable {
                // Chevron icon
                Image(uiImage: .chevronImage)
                    .flipsForRightToLeftLayoutDirection(true)
                    .foregroundStyle(Color(.textTertiary))
            }
        }
        .padding(Constants.hStackPadding)
        .frame(minHeight: Constants.height)
        .onTapGesture {
            if isEditable {
                // todo-13493 add tap handling
            }
        }
    }
}


// MARK: - Constants
//
extension CustomFieldsDetailsView {
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
        CustomFieldsDetailsView(
            isEditable: false,
            customFields: [
            CustomFieldsViewModel(id: 0, title: "First Title", content: "First Content"),
            CustomFieldsViewModel(id: 1, title: "Second Title", content: "Second Content", contentURL: URL(string: "https://woocommerce.com/"))
        ])
    }
}

#endif
