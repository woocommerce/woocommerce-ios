import SwiftUI

struct ItemRowView: View {
    private let cartItem: CartItem
    private let onItemRemoveTapped: (() -> Void)?

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.colorScheme) var colorScheme
    @Binding private var showProductImage: Bool

    init(cartItem: CartItem, showImage: Binding<Bool> = .constant(true), onItemRemoveTapped: (() -> Void)? = nil) {
        self.cartItem = cartItem
        self._showProductImage = showImage
        self.onItemRemoveTapped = onItemRemoveTapped
    }

    var body: some View {
        HStack(spacing: Constants.horizontalElementSpacing) {
            productImage

            VStack(alignment: .leading, spacing: Constants.itemTitleAndPriceSpacing * (1 / scale)) {
                Text(cartItem.title)
                    .foregroundColor(Color.posPrimaryText)
                    .font(Constants.itemTitleFont)
                if let subtitle = cartItem.subtitle {
                    Text(subtitle)
                        .foregroundColor(Color.posSecondaryText)
                        .font(Constants.itemSubtitleFont)
                }
                Text(cartItem.item.formattedPrice)
                    .foregroundColor(Color.posSecondaryText)
                    .font(Constants.itemPriceFont)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, showProductImage ? 0 : Constants.cardContentHorizontalPadding)
            .accessibilityElement(children: .combine)

            if let onItemRemoveTapped {
                Button(action: {
                    onItemRemoveTapped()
                }, label: {
                    Image(systemName: "xmark.circle")
                        .font(.posBodyLargeRegular)
                })
                .accessibilityLabel(Localization.removeFromCartAccessibilityLabel)
                .padding(.trailing, Constants.cardContentHorizontalPadding)
                .foregroundColor(Color.posOnSurfaceVariantLowest)
            }
        }
        .frame(maxWidth: .infinity, idealHeight: Constants.productCardSize * scale)
        .background(Color.posSurfaceContainerLowest)
        .overlay {
            RoundedRectangle(cornerRadius: Constants.productCardCornerRadius)
                .stroke(Color.posCartItemOutline, lineWidth: cardOutlineWidth)
        }
        .clipShape(RoundedRectangle(cornerRadius: Constants.productCardCornerRadius))
        .padding(.horizontal, Constants.horizontalPadding)
    }

    @ViewBuilder
    private var productImage: some View {
        if !showProductImage {
            EmptyView()
        } else if let imageSource = cartItem.item.productImageSource {
            ProductImageThumbnail(productImageURL: URL(string: imageSource),
                                  productImageSize: Constants.productCardSize,
                                  scale: scale,
                                  foregroundColor: .clear,
                                  cachesOriginalImage: true)
            .frame(width: min(Constants.productCardSize * scale, Constants.maximumProductCardSize),
                   height: Constants.productCardSize * scale)
            .clipped()
        } else {
            Rectangle()
                .frame(width: min(Constants.productCardSize * scale, Constants.maximumProductCardSize),
                       height: Constants.productCardSize * scale)
                .foregroundColor(Color(.secondarySystemFill))
        }
    }
}

private extension ItemRowView {
    var cardOutlineWidth: CGFloat {
        switch colorScheme {
        case .dark:
            return 0
        default:
            return Constants.cardOutlineWidth
        }
    }
}

private extension ItemRowView {
    enum Constants {
        static let productCardSize: CGFloat = 96
        static let maximumProductCardSize: CGFloat = Self.productCardSize * 1.5
        static let productCardCornerRadius: CGFloat = 8
        static let cardOutlineWidth: CGFloat = 1
        static let horizontalPadding: CGFloat = 16
        static let horizontalElementSpacing: CGFloat = 16
        static let cardContentHorizontalPadding: CGFloat = 16
        static let itemTitleAndPriceSpacing: CGFloat = 4
        static let itemTitleFont: POSFontStyle = .posBodySmallEmphasized
        static let itemSubtitleFont: POSFontStyle = .posBodySmallLight
        static let itemPriceFont: POSFontStyle = .posBodySmallLight
    }

    enum Localization {
        static let removeFromCartAccessibilityLabel = NSLocalizedString(
            "pointOfSale.item.removeFromCart.button.accessibilityLabel",
            value: "Remove",
            comment: "The accessibility label for the `x` button next to each item in the Point of Sale cart." +
            "The button removes the item. The translation should be short, to make it quick to navigate by voice.")
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    ItemRowView(cartItem: CartItem(id: UUID(),
                                   item: PointOfSalePreviewItemService().providePointOfSaleItem(),
                                   title: "Item Title",
                                   subtitle: "Item Subtitle",
                                   quantity: 2),
                onItemRemoveTapped: { })
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    ItemRowView(cartItem: CartItem(id: UUID(),
                                   item: PointOfSalePreviewItemService().providePointOfSaleItem(),
                                   title: "Item Title",
                                   subtitle: nil,
                                   quantity: 2),
                onItemRemoveTapped: { })
}
#endif
