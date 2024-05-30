import SwiftUI
import struct Yosemite.CartProduct

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
                .padding(.horizontal, 32)
                .foregroundColor(Color.primaryBackground)
            Spacer()
            Button(action: {
                onProductRemoveTapped?()
            }, label: {
                Image(systemName: "x.circle")
            })
            .frame(width: 56, height: 56, alignment: .trailing)
            .padding(.horizontal, 32)
            .foregroundColor(Color.lightBlue)
            .background(Color(.clear))
        }
        .frame(maxWidth: .infinity, idealHeight: 120)
        .foregroundColor(Color.tertiaryBackground)
    }
}

#if DEBUG
//#Preview {
//    ProductRowView(cartProduct: CartProduct(id: UUID(),
//                                            product: POSProductProvider.provideProductForPreview(currencySettings: .init()),
//                                            quantity: 2))
//}
#endif
