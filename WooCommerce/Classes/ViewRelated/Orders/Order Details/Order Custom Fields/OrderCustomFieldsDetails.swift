import SwiftUI

struct OrderCustomFieldsDetails: View {
    @Environment(\.presentationMode) var presentationMode

    let customFields: [OrderCustomFieldsViewModel]

    var body: some View {
        NavigationView {
            GeometryReader { geometry in

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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Image(uiImage: .closeButton)
                    })
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Custom Fields")
            .navigationBarTitleDisplayMode(.inline)
            .wooNavigationBarStyle()
        }
    }
}

struct OrderMetadataDetails_Previews: PreviewProvider {
    static var previews: some View {
        OrderCustomFieldsDetails(customFields: [
            OrderCustomFieldsViewModel(id: 0, title: "First Title", content: "First Content"),
            OrderCustomFieldsViewModel(id: 1, title: "Second Title", content: "Second Content")
        ])
    }
}
