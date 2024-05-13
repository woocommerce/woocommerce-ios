import SwiftUI

struct ProductRowView: View {
    var body: some View {
        Text("Product XYZ")
            .frame(maxWidth: .infinity)
            .border(Color.gray, width: 1)
    }
}

#Preview {
    ProductRowView()
}
