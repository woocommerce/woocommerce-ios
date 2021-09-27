import SwiftUI

/// Represent a row of a Product Item that should be fulfilled
///
struct ItemToFulfillRow: View, Identifiable {
    let id = UUID()
    let productOrVariationID: Int64
    let title: String
    let subtitle: String

    var body: some View {
        TitleAndSubtitleRow(title: title, subtitle: subtitle)
    }
}

struct ItemToFulfillRow_Previews: PreviewProvider {
    static var previews: some View {
        ItemToFulfillRow(productOrVariationID: 123, title: "Title", subtitle: "My subtitle")
            .previewLayout(.fixed(width: 375, height: 100))
    }
}
