import Yosemite
import SwiftUI

struct OrderMetadataDetails: View {
    let customFields: [OrderMetaData]
    
    var body: some View {
        Text("Order metadata goes here")
    }
}

struct OrderMetadataDetails_Previews: PreviewProvider {
    static var previews: some View {
        OrderMetadataDetails(customFields: [])
    }
}
