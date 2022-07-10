import SwiftUI

struct OrderCustomFieldsDetails: View {
    @Environment(\.presentationMode) var presentationMode

    let customFields: [OrderCustomFieldsViewModel]

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {

                    Color(.listBackground).edgesIgnoringSafeArea(.all)

                    VStack(alignment: .leading) {
                        ForEach(customFields) { customField in
                            TitleAndSubtitleRow(
                                title: customField.title,
                                subtitle: customField.content
                            )
                            Divider()
                                .padding(.leading)
                        }
                    }
                    .background(Color(.basicBackground))
                }
            }
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
            .wooNavigationBarStyle()
        }
    }
}

// MARK: - Constants
//
extension OrderCustomFieldsDetails {
    enum Localization {
        static let title = NSLocalizedString("Custom Fields", comment: "Title for the order custom fields list")
    }
}

struct OrderCustomFieldsDetails_Previews: PreviewProvider {
    static var previews: some View {
        OrderCustomFieldsDetails(customFields: [
            OrderCustomFieldsViewModel(id: 0, title: "First Title", content: "First Content"),
            OrderCustomFieldsViewModel(id: 1, title: "Second Title", content: "Second Content")
        ])
    }
}
