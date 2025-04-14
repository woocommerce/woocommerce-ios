import SwiftUI

struct ItemRowView: View {
    private let cartItem: CartItem.PurchasableItem
    private let onItemRemoveTapped: (() -> Void)?

    @ScaledMetric private var scale: CGFloat = 1.0
    @Binding private var showProductImage: Bool

    private var dimension: CGFloat {
        min(Constants.productCardSize * scale, Constants.maximumProductCardSize)
    }

    init(cartItem: CartItem.PurchasableItem, showImage: Binding<Bool> = .constant(true), onItemRemoveTapped: (() -> Void)? = nil) {
        self.cartItem = cartItem
        self._showProductImage = showImage
        self.onItemRemoveTapped = onItemRemoveTapped
    }

    var body: some View {
        HStack(spacing: Constants.horizontalElementSpacing) {
            productImage

            VStack(alignment: .leading, spacing: Constants.itemTitleAndPriceSpacing * (1 / scale)) {
                Text(cartItem.title)
                    .foregroundColor(PointOfSaleItemListCardConstants.titleColor)
                    .font(Constants.itemTitleFont)
                if let subtitle = cartItem.subtitle {
                    Text(subtitle)
                        .foregroundColor(PointOfSaleItemListCardConstants.detailColor)
                        .font(Constants.itemSubtitleFont)
                }
                Text(cartItem.item.formattedPrice)
                    .foregroundColor(PointOfSaleItemListCardConstants.detailColor)
                    .font(Constants.itemPriceFont)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, showProductImage ? 0 : Constants.cardContentHorizontalPadding)
            .accessibilityElement(children: .combine)

            if let onItemRemoveTapped {
                CartRowRemoveButton {
                    onItemRemoveTapped()
                }
            }
        }
        .padding(.trailing, Constants.cardContentHorizontalPadding)
        .frame(maxWidth: .infinity, idealHeight: Constants.productCardSize * scale)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
        .padding(.horizontal, Constants.horizontalPadding)
    }

    @ViewBuilder
    private var productImage: some View {
        if !showProductImage {
            EmptyView()
        } else {
            POSItemImageView(imageSource: cartItem.item.productImageSource,
                             imageSize: dimension,
                             scale: 1)
            .frame(width: dimension, height: dimension)
        }
    }
}

private extension ItemRowView {
    enum Constants {
        static let productCardSize: CGFloat = 96
        static let maximumProductCardSize: CGFloat = Self.productCardSize * 1.5
        static let horizontalPadding: CGFloat = POSPadding.medium
        static let horizontalElementSpacing: CGFloat = POSSpacing.medium
        static let cardContentHorizontalPadding: CGFloat = POSPadding.medium
        static let itemTitleAndPriceSpacing: CGFloat = POSSpacing.xSmall
        static let itemTitleFont: POSFontStyle = .posBodySmallBold
        static let itemSubtitleFont: POSFontStyle = .posBodySmallRegular()
        static let itemPriceFont: POSFontStyle = .posBodySmallRegular()
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    ItemRowView(cartItem: CartItem.PurchasableItem(id: UUID(),
                                                   item: PointOfSalePreviewItemService().providePointOfSaleItem(),
                                                   title: "Item Title",
                                                   subtitle: "Item Subtitle",
                                                   quantity: 2),
                onItemRemoveTapped: { })
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    ItemRowView(cartItem: CartItem.PurchasableItem(id: UUID(),
                                                   item: PointOfSalePreviewItemService().providePointOfSaleItem(),
                                                   title: "Item Title",
                                                   subtitle: nil,
                                                   quantity: 2),
                onItemRemoveTapped: { })
}
#endif
