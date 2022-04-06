import SwiftUI

/// View to select products
///
struct SelectProducts: View {
    @State private var query: String = ""
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SearchHeader(filterText: $query, filterPlaceholder: "Search Products")
            }
            HStack {
                Button("Select All") {
                    // TODO: select all item
                }
                .buttonStyle(LinkButtonStyle())
                .fixedSize()
                Spacer()
                Button("Filter") {
                    // TODO: show filter view
                }
                .buttonStyle(LinkButtonStyle())
                .fixedSize()
            }
        }
    }
}

struct SelectProducts_Previews: PreviewProvider {
    static var previews: some View {
        SelectProducts()
    }
}
