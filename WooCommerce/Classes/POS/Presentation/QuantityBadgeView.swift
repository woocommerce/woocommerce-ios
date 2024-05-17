import SwiftUI

struct QuantityBadgeView: View {
    private let productQuantity: Int

    init(_ productQuantity: Int) {
        self.productQuantity = productQuantity
    }

    var body: some View {
        Text("\(productQuantity)")
            .foregroundColor(Color.white)
    }
}

#Preview {
    QuantityBadgeView(3)
}
