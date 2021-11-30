import SwiftUI

/// This view represent a single element of the HubMenu
///
struct HubMenuElement: View {

    let icon: Image
    let text: String

    var body: some View {
        Text("Work in progress")
    }
}

struct HubMenuElement_Previews: PreviewProvider {
    static var previews: some View {
        HubMenuElement(icon: Image("icon-hub-menu"),
                       text: "Ciao")
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("Row Not Selectable")
    }
}
