import SwiftUI

struct ProductCardView: View {
    private let product: POSProduct
    private let onProductCardTapped: (() -> Void)?

    init(product: POSProduct, onProductCardTapped: (() -> Void)? = nil) {
        self.product = product
        self.onProductCardTapped = onProductCardTapped
    }

    var outOfStock: Bool {
        // TODO: Handle out of stock
        // wp.me/p91TBi-bcW#comment-12123
        product.stockQuantity <= 0
    }

    var body: some View {
            VStack {
                Text(product.name)
                    .foregroundStyle(Color.primaryBackground)
                Text(outOfStock ? "Out of Stock" : product.price)
                    .foregroundStyle(Color.primaryBackground)
                HStack(spacing: 8) {
                    QuantityBadgeView(product.stockQuantity)
                        .frame(width: 50, height: 50)
                    Spacer()
                    Button(action: {
                        onProductCardTapped?()
                    }, label: { })
                    .buttonStyle(POSPlusButtonStyle())
                    .frame(width: 50, height: 50)
                }
            }
            .frame(maxWidth: .infinity)
            .background(outOfStock ? Color.pink : Color.tertiaryBackground)
    }
}

#if DEBUG
#Preview {
    ProductCardView(product: POSProductFactory.makeProduct())
}
#endif
