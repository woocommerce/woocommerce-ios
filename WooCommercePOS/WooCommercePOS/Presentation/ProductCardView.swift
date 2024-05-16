import SwiftUI

struct ProductCardView: View {
    private let product: Product
    private let onProductCardTapped: (() -> Void)?

    init(product: Product, onProductCardTapped: (() -> Void)? = nil) {
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
                    QuantityBadgeView()
                        .frame(width: 56, height: 56)
                    Spacer()
                    Button(action: {
                        onProductCardTapped?()
                    }, label: { })
                    .buttonStyle(PlusButtonStyle())
                    .frame(width: 56, height: 56)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.tertiaryBackground)
    }
}

#Preview {
    ProductCardView(product: ProductFactory.makeProduct())
}
