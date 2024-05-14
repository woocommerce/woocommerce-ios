import SwiftUI

struct ProductRowView: View {
    var body: some View {
        Text("Product XYZ")
            .foregroundColor(Color.primaryText)
            .frame(maxWidth: .infinity)
            .border(Color.gray, width: 1)
            .foregroundColor(Color.tertiaryBackground)
    }
}

#Preview {
    ProductRowView()
}
