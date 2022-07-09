import Yosemite
import SwiftUI

struct OrderCustomFieldsDetails: View {
    let customFields: [OrderMetaData]

    var body: some View {
        NavigationView {
            GeometryReader { geometry in

                Color(.listBackground).edgesIgnoringSafeArea(.all)

                VStack(alignment: .leading) {
                    ForEach(customFields, id: \.self) { customField in
                        TitleAndSubtitleRow(
                            title: customField.key,
                            subtitle: customField.value
                        )
                    }
                }.background(Color(.basicBackground))

            }.navigationTitle("Custom Fields")
        }
    }
}

struct OrderMetadataDetails_Previews: PreviewProvider {
    static var previews: some View {
        OrderCustomFieldsDetails(customFields: [
            OrderMetaData(metadataID: 0, key: "First Key", value: "First Value"),
            OrderMetaData(metadataID: 1, key: "Second Key", value: "Second Value")
        ])
    }
}
