import SwiftUI

struct PointOfSaleItemListEmptyView: View {
    var body: some View {
        VStack {
            Image(uiImage: .searchImage)
            Text("No supported products found")
        }
    }
}
