import SwiftUI
import class WooFoundation.CurrencyFormatter
import struct Yosemite.POSProduct
import protocol Yosemite.POSItem

struct ItemCardView: View {
    private let item: POSItem
    private let onItemCardTapped: (() -> Void)?

    init(item: POSItem, onItemCardTapped: (() -> Void)? = nil) {
        self.item = item
        self.onItemCardTapped = onItemCardTapped
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
                        onItemCardTapped?()
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
