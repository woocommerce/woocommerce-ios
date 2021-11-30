import SwiftUI

/// This view represent a single element of the HubMenu
///
struct HubMenuElement: View {
    let image: UIImage
    let text: String

    var body: some View {
        VStack {
            Image(uiImage: image)
            Text("Work in progress")
        }
    }
}

struct HubMenuElement_Previews: PreviewProvider {
    static var previews: some View {

        HubMenuElement(image: UIImage(named: "icon-hub-menu")!,
                       text: "Ciao")
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("Row Not Selectable")
    }
}
