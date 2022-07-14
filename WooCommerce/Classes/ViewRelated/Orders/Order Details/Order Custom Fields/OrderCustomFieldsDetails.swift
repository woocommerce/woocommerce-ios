import SwiftUI

struct OrderCustomFieldsDetails: View {
    @Environment(\.presentationMode) var presentationMode

    let customFields: [OrderCustomFieldsViewModel]

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(customFields) { customField in
                            CustomFieldRow(title: customField.title,
                                           content: customField.content,
                                           contentURL: customField.contentURL)
                            Divider()
                                .padding(.leading)
                        }
                    }
                    .padding(.horizontal, insets: geometry.safeAreaInsets)
                    .background(Color(.listForeground))
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
                } else { // Display content as plain text
                    Text(content)
                        .footnoteStyle()
                }
            }.padding([.leading, .trailing], Constants.vStackPadding)

            Spacer()
        }
        .padding([.top, .bottom], Constants.hStackPadding)
        .frame(minHeight: Constants.height)
    }
}

// MARK: - Constants
//
extension OrderCustomFieldsDetails {
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
        OrderCustomFieldsDetails(customFields: [
            OrderCustomFieldsViewModel(id: 0, title: "First Title", content: "First Content"),
            OrderCustomFieldsViewModel(id: 1, title: "Second Title", content: "Second Content", contentURL: URL(string: "https://woocommerce.com/"))
        ])
    }
}

#endif
