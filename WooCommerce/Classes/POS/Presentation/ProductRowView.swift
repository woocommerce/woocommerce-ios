import SwiftUI

struct ProductRowView: View {
    private let cartProduct: CartProduct
    private let onProductRemoveTapped: (() -> Void)?

    init(cartProduct: CartProduct, onProductRemoveTapped: (() -> Void)? = nil) {
        self.cartProduct = cartProduct
        self.onProductRemoveTapped = onProductRemoveTapped
    }

    var body: some View {
        HStack {
            Text(cartProduct.product.name)
                .foregroundColor(Color.white)
            Button(action: {
                onProductRemoveTapped?()
            }, label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(Color.white)
            })
        }
        .frame(maxWidth: .infinity)
        .border(Color.gray, width: 1)
        .foregroundColor(Color.tertiaryBackground)
    }
}

#Preview {
    ProductRowView(cartProduct: CartProduct(id: UUID(),
                                            product: POSProductFactory.makeProduct(),
                                            quantity: 2))
}
