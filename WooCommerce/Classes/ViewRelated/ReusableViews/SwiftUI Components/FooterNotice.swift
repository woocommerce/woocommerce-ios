import SwiftUI

/// Renders a info notice with an icon
///
struct FooterNotice: View {

    /// Content to be rendered next to the info icon.
    ///
    let infoText: String

    var body: some View {
        HStack {
            Image(uiImage: .infoOutlineImage)
            Text(infoText)
        }
        .footnoteStyle()
        .padding([.leading, .trailing]).padding(.top, 4)
    }
}

struct FooterNotice_Previews: PreviewProvider {
    static var previews: some View {
        FooterNotice(infoText: "This is a notice")
    }
}
