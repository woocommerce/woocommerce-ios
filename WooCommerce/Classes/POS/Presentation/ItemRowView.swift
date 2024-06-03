import class Yosemite.POSProductProvider
import SwiftUI

struct ItemRowView: View {
    private let cartItem: CartItem
    private let onItemRemoveTapped: (() -> Void)?

    init(cartItem: CartItem, onItemRemoveTapped: (() -> Void)? = nil) {
        self.cartItem = cartItem
        self.onItemRemoveTapped = onItemRemoveTapped
    }

    var body: some View {
        HStack {
            Text(cartItem.item.name)
                .padding(.horizontal, 32)
                .foregroundColor(Color.primaryBackground)
            Spacer()
            Button(action: {
                onItemRemoveTapped?()
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
#Preview {
    // TODO: https://github.com/woocommerce/woocommerce-ios/issues/12917
    // The Yosemite imports are only needed for previews
    ItemRowView(cartItem: CartItem(id: UUID(),
                                      item: POSProductProvider.provideProductForPreview(),
                                      quantity: 2),
                onItemRemoveTapped: { })
}
#endif
