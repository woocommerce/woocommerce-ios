import Yosemite
import SwiftUI

struct OrderCustomFieldsDetails: View {
    let customFields: [OrderMetaData]

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                List {
                    ForEach(customFields, id: \.self) { customField in
                        Text(customField.value)
                    }
                }
            }.navigationTitle("Custom Fields")
        }
    }
}

struct OrderMetadataDetails_Previews: PreviewProvider {
    static var previews: some View {
        OrderCustomFieldsDetails(customFields: [])
    }
}
