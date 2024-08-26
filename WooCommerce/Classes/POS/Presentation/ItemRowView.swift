import SwiftUI

struct ItemRowView: View {
    private let cartItem: CartItem
    private let onItemRemoveTapped: (() -> Void)?

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.colorScheme) var colorScheme

    init(cartItem: CartItem, onItemRemoveTapped: (() -> Void)? = nil) {
        self.cartItem = cartItem
        self.onItemRemoveTapped = onItemRemoveTapped
    }

    var body: some View {
        HStack(spacing: Constants.horizontalCardSpacing) {
            productImage

            VStack(alignment: .leading, spacing: Constants.itemNameAndPriceSpacing) {
                Text(cartItem.item.name)
                    .foregroundColor(Color.posPrimaryText)
                    .font(Constants.itemNameFont)
                    .padding(.horizontal, Constants.horizontalElementSpacing)
                    .padding(.top, Constants.verticalPadding)
                Text(cartItem.item.formattedPrice)
                    .foregroundColor(Color.posPrimaryText)
                    .font(Constants.itemPriceFont)
                    .padding(.horizontal, Constants.horizontalElementSpacing)
                    .padding(.bottom, Constants.verticalPadding)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            if let onItemRemoveTapped {
                Button(action: {
                    onItemRemoveTapped()
                }, label: {
                    Image(systemName: "xmark.circle")
                        .font(.posBodyRegular)
                })
                .accessibilityLabel(Localization.removeFromCartAccessibilityLabel)
                .padding()
                .foregroundColor(Color.posTertiaryText)
            }
        }
        .frame(maxWidth: .infinity, idealHeight: Constants.productCardSize * scale)
        .background(backgroundColor)
        .overlay {
            RoundedRectangle(cornerRadius: Constants.productCardCornerRadius)
                .stroke(Color.black, lineWidth: Constants.nilOutline)
        }
        .clipShape(RoundedRectangle(cornerRadius: Constants.productCardCornerRadius))
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
    }

    @ViewBuilder
    private var productImage: some View {
        if dynamicTypeSize >= .accessibility3 {
            EmptyView()
        } else if let imageSource = cartItem.item.productImageSource {
            ProductImageThumbnail(productImageURL: URL(string: imageSource),
                                  productImageSize: Constants.productCardSize,
                                  scale: scale,
                                  foregroundColor: .clear)
            .frame(width: min(Constants.productCardSize * scale, Constants.maximumProductCardSize),
                   height: Constants.productCardSize * scale)
            .clipped()
        } else {
            // TODO:
            // Handle what we'll show when there's lack of images:
            Rectangle()
                .frame(width: min(Constants.productCardSize * scale, Constants.maximumProductCardSize),
                       height: Constants.productCardSize * scale)
                .foregroundColor(Color(.secondarySystemFill))
        }
    }
}

private extension ItemRowView {
    var backgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color.posTertiaryBackground
        default:
            return Color.posSecondaryBackground
        }
    }
}

private extension ItemRowView {
    enum Constants {
        static let productCardSize: CGFloat = 72
        static let maximumProductCardSize: CGFloat = Self.productCardSize * 1.5
        static let productCardCornerRadius: CGFloat = 8
        // The use of stroke means the shape is rendered as an outline (border) rather than a filled shape,
        // since we still have to give it a value, we use 0 so it renders no border but it's shaped as one.
        static let nilOutline: CGFloat = 0
        static let verticalPadding: CGFloat = 4
        static let horizontalPadding: CGFloat = 16
        static let horizontalCardSpacing: CGFloat = 0
        static let horizontalElementSpacing: CGFloat = 16
        static let itemNameAndPriceSpacing: CGFloat = 8
        static let itemNameFont: POSFontStyle = .posDetailEmphasized
        static let itemPriceFont: POSFontStyle = .posDetailLight
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
#Preview {
    ItemRowView(cartItem: CartItem(id: UUID(),
                                   item: POSItemProviderPreview().providePointOfSaleItem(),
                                   quantity: 2),
                onItemRemoveTapped: { })
}
#endif
