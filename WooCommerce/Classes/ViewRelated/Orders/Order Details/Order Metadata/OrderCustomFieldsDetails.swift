import Yosemite
import SwiftUI

struct OrderCustomFieldsDetails: View {
    let customFields: [OrderMetaData]

    var body: some View {
        NavigationView {
            GeometryReader { geometry in

                Color(.listBackground).edgesIgnoringSafeArea(.all)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(customFields, id: \.self) { customField in
                        CustomFieldView(customField: customField)
                    }
                }
            }.navigationTitle("Custom Fields")
        }

    }
}

private struct CustomFieldView: View {
    let customField: OrderMetaData

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
                    Divider()

            Text(customField.key)
                        .headlineStyle()
                        .padding([.leading, .trailing])

                    HStack(alignment: .bottom) {
                        Text(customField.value)
                            .bodyStyle()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding([.leading, .trailing])

                    Divider()
                }
                .background(Color(.basicBackground))
    }
}

struct OrderMetadataDetails_Previews: PreviewProvider {
    static var previews: some View {
        OrderCustomFieldsDetails(customFields: [])
    }
}
