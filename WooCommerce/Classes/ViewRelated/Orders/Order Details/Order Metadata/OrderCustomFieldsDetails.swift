import Yosemite
import SwiftUI

struct OrderCustomFieldsDetails: View {
    let customFields: [OrderMetaData]

    var body: some View {
        VStack {
            List {
                ForEach(customFields, id: \.self) { customField in
                    Text(customField.value)
                }
            }
        }
    }
}

struct OrderMetadataDetails_Previews: PreviewProvider {
    static var previews: some View {
        OrderCustomFieldsDetails(customFields: [])
    }
}
