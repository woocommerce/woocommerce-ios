import SwiftUI
import class WooFoundation.CurrencyFormatter
import struct Yosemite.POSProduct
import protocol Yosemite.POSItem

struct ProductCardView: View {
    private let item: POSItem
    private let onProductCardTapped: (() -> Void)?

    init(item: POSItem, onProductCardTapped: (() -> Void)? = nil) {
        self.item = item
        self.onProductCardTapped = onProductCardTapped
    }

    var body: some View {
            VStack {
                Text(item.name)
                    .foregroundStyle(Color.primaryBackground)
                Text(item.formattedPrice)
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
