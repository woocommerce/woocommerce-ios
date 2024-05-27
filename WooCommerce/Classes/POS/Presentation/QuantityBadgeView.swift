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

#if DEBUG
#Preview {
    QuantityBadgeView(3)
}
#endif
