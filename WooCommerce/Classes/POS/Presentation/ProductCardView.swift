import SwiftUI

struct ProductCardView: View {
    private let product: POSProduct
    private let onProductCardTapped: (() -> Void)?

    init(product: POSProduct, onProductCardTapped: (() -> Void)? = nil) {
        self.product = product
        self.onProductCardTapped = onProductCardTapped
    }

    var body: some View {
            VStack {
                Text(product.name)
                    .foregroundStyle(Color.primaryBackground)
                Text(product.price)
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
            .background(Color.tertiaryBackground)
    }
}

#if DEBUG
#Preview {
    ProductCardView(product: POSProductFactory.makeProduct())
}
#endif
