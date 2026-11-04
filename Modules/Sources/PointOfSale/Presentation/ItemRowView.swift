import SwiftUI

struct ItemRowView: View {
    private let cartItem: Cart.PurchasableItem
    private let showsDiscountedNote: Bool
    private let onItemRemoveTapped: (() -> Void)?
    private let onCancelLoading: (() -> Void)?

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.posMetrics) private var metrics
    @Binding private var showProductImage: Bool

    private var dimension: CGFloat {
        min(metrics.cartRowSize * scale, metrics.cartRowSize * Constants.maximumCardSizeMultiplier)
    }

    init(cartItem: Cart.PurchasableItem,
         showsDiscountedNote: Bool = false,
         showImage: Binding<Bool> = .constant(true),
         onItemRemoveTapped: (() -> Void)? = nil,
         onCancelLoading: (() -> Void)? = nil) {
        self.cartItem = cartItem
        self.showsDiscountedNote = showsDiscountedNote
        self._showProductImage = showImage
        self.onItemRemoveTapped = onItemRemoveTapped
        self.onCancelLoading = onCancelLoading
    }

    var body: some View {
        itemRow
            .padding(.horizontal, metrics.padding.medium)
            .geometryGroup()
            .accessibilityLabel(accessibilityLabel)
            .accessibilityIdentifier(accessibilityIdentifier)
    }

    @ViewBuilder
    private var itemRow: some View {
        switch cartItem.state {
        case .loaded, .error:
            productRow
        case .loading:
            GhostItemCardView(configuration: Constants.cartConfiguration,
                              showProductImage: $showProductImage) {
                if let onCancelLoading {
                    CartRowRemoveButton {
                        onCancelLoading()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var productRow: some View {
        HStack(spacing: metrics.spacing.medium) {
            productImage
                .frame(width: dimension)
                .frame(minHeight: dimension)

            VStack(alignment: .leading, spacing: metrics.spacing.xSmall * (1 / scale)) {
                Text(cartItem.title)
                    .foregroundColor(PointOfSaleItemListCardConstants.titleColor)
                    .font(Constants.itemTitleFont)
                if let subtitle = cartItem.subtitle {
                    Text(subtitle)
                        .foregroundColor(subtitleColor)
                        .font(Constants.itemSubtitleFont)
                }

                if case .loaded(let item) = cartItem.state {
                    Text(item.formattedPrice)
                        .foregroundColor(PointOfSaleItemListCardConstants.detailColor)
                        .font(Constants.itemPriceFont)
                }

                if showsDiscountedNote {
                    Text(Localization.discountApplied)
                        .foregroundColor(.posSuccess)
                        .font(Constants.itemPriceFont)
                }
            }
            .animation(.default, value: showsDiscountedNote)
            .multilineTextAlignment(.leading)
            .lineLimit(Constants.titleSubtitleLineLimit)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, showProductImage ? 0 : metrics.padding.medium * (1 / scale))
            .padding(.vertical, metrics.padding.small * (1 / scale))
            if let onItemRemoveTapped {
                CartRowRemoveButton {
                    onItemRemoveTapped()
                }
            }
        }
        .padding(.trailing, metrics.padding.medium)
        .frame(maxWidth: .infinity, minHeight: dimension, alignment: .leading)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
    }

    @ViewBuilder
    private var productImage: some View {
        if !showProductImage {
            EmptyView()
        } else if case .loaded(let item) = cartItem.state {
            POSItemImageView(imageSource: item.productImageSource,
                             imageSize: dimension,
                             scale: 1)
        } else if case .error = cartItem.state {
            POSItemImageView(imageSource: nil,
                             imageSize: dimension,
                             scale: 1,
                             state: .error)
        }
    }

    private var subtitleColor: Color {
        switch cartItem.state {
        case .loaded, .loading:
            return PointOfSaleItemListCardConstants.detailColor
        case .error:
            return .posError
        }
    }

    private var accessibilityLabel: String {
        if let accessibilityLabel = cartItem.accessibilityLabel {
            accessibilityLabel
        } else {
            [cartItem.title, cartItem.subtitle, cartItem.formattedPrice, showsDiscountedNote ? Localization.discountApplied : nil]
                .compactMap { $0 }
                .joined(separator: ",")
        }
    }

    private var accessibilityIdentifier: String {
        let identifier = cartItem.posItemIdentifier
        switch identifier.underlyingType {
        case .product:
            return "pos-cart-item-product-\(identifier.itemID)"
        case .variation:
            return "pos-cart-item-variation-\(identifier.itemID)"
        case .coupon, .loading, .error:
            return "pos-cart-item-\(identifier.itemID)"
        }
    }
}

private extension ItemRowView {
    enum Localization {
        static let discountApplied = NSLocalizedString(
            "pointOfSale.itemRow.discountApplied",
            value: "Discount applied",
            comment: "Note shown on a product row in the Point of Sale cart at checkout when the "
                + "order response shows the line item received a discount, from a coupon or another source.")
    }

    enum Constants {
        static let maximumCardSizeMultiplier: CGFloat = 1.5
        static let itemTitleFont: POSFontStyle = .posBodySmallBold()
        static let itemSubtitleFont: POSFontStyle = .posBodySmallRegular()
        static let itemPriceFont: POSFontStyle = .posBodySmallRegular()
        static let titleSubtitleLineLimit: Int = 4

        static let cartConfiguration = GhostItemCardViewConfiguration(
            titleFont: Constants.itemTitleFont,
            detailFont: Constants.itemPriceFont,
            detailPlaceholderLength: (regular: 25, accessibility: 4),
            cardSize: \.cartRowSize,
            maximumCardSizeMultiplier: Constants.maximumCardSizeMultiplier,
            backgroundColor: Color.posSurfaceContainerLowest
        )
    }
}

#if DEBUG
#Preview {
    ScrollView {
        ItemRowView(
            cartItem: Cart.PurchasableItem(
                id: UUID(),
                item: PointOfSalePreviewItemService().providePointOfSaleItem(),
                title: "Item Title",
                subtitle: "Item Subtitle",
                quantity: 2
            ),
            onItemRemoveTapped: { }
        )

        ItemRowView(
            cartItem: Cart.PurchasableItem(
                id: UUID(),
                item: PointOfSalePreviewItemService().providePointOfSaleItem(),
                title: "Item Title With incredible long title that goes incredibly far and beyond",
                subtitle: "Item Subtitle",
                quantity: 2
            ),
            onItemRemoveTapped: { }
        )

        ItemRowView(
            cartItem: Cart.PurchasableItem(
                id: UUID(),
                item: PointOfSalePreviewItemService().providePointOfSaleItem(),
                title: "Item Title",
                subtitle: nil,
                quantity: 2
            ),
            onItemRemoveTapped: { }
        )

        ItemRowView(
            cartItem: Cart.PurchasableItem(
                id: UUID(),
                item: PointOfSalePreviewItemService().providePointOfSaleItem(),
                title: "Discounted Item",
                subtitle: "Item Subtitle",
                quantity: 2
            ),
            showsDiscountedNote: true,
            onItemRemoveTapped: { }
        )

        ItemRowView(
            cartItem: Cart.PurchasableItem.loading(id: UUID()),
            onCancelLoading: { }
        )

        ItemRowView(
            cartItem: Cart.PurchasableItem(
                id: UUID(),
                title: "123-123-123",
                subtitle: "Unspported product type",
                quantity: 1,
                state: .error
            )
        )

        ItemRowView(
            cartItem: Cart.PurchasableItem(
                id: UUID(),
                title: "123-123-123",
                subtitle: "Unspported product type with an incredibly long error message that goes on and on",
                quantity: 1,
                state: .error
            )
        )

        ItemRowView(
            cartItem: Cart.PurchasableItem(
                id: UUID(),
                item: PointOfSalePreviewItemService().providePointOfSaleItem(),
                title: "Item Title",
                subtitle: nil,
                quantity: 2
            ),
            showImage: .constant(false),
            onItemRemoveTapped: { }
        )

        ItemRowView(
            cartItem: Cart.PurchasableItem.loading(id: UUID()),
            showImage: .constant(false),
            onCancelLoading: { }
        )
    }
    .frame(width: 400)
}
#endif
