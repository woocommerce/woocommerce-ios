import SwiftUI

struct ProductCardView: View {
    private let product: Product
    private var onProductCardTapped: (() -> Void)?

    init(product: Product, onProductCardTapped: (() -> Void)? = nil) {
        self.product = product
        self.onProductCardTapped = onProductCardTapped
    }

    var body: some View {
        Rectangle()
            .fill(Color.tertiaryBackground)
            .frame(minWidth: 200, maxWidth: .infinity, minHeight: 200)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                VStack {
                    Text(product.name)
                        .foregroundStyle(Color.primaryBackground)
                    Text(product.price)
                        .foregroundStyle(Color.primaryBackground)
                    HStack {
                        QuantityBadgeView()
                        PlusButtonView {
                            onProductCardTapped?()
                        }
                    }
                }
            }
    }
}

#Preview {
    ProductCardView(product: ProductFactory.makeProduct())
}
