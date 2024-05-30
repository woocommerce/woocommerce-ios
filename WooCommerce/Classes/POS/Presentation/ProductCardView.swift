import SwiftUI
import class WooFoundation.CurrencyFormatter
import struct Yosemite.POSProduct

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
                Text(product.priceWithCurrency)
                    .foregroundStyle(Color.primaryBackground)
                HStack(spacing: 8) {
                    Spacer()
                    Button(action: {
                        onProductCardTapped?()
                    }, label: { })
                    .buttonStyle(POSPlusButtonStyle())
                    .frame(width: 56, height: 56)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.tertiaryBackground)
    }
}

#if DEBUG
//#Preview {
//    ProductCardView(product: POSProductProvider.provideProductForPreview(currencySettings: .init()))
//}
#endif
