import SwiftUI

struct ItemRowView: View {
    private let cartItem: Cart.PurchasableItem
    private let onItemRemoveTapped: (() -> Void)?
    private let onCancelLoading: (() -> Void)?

    @ScaledMetric private var scale: CGFloat = 1.0
    @Binding private var showProductImage: Bool

    private var dimension: CGFloat {
        min(Constants.productCardSize * scale, Constants.maximumProductCardSize)
    }

    init(cartItem: Cart.PurchasableItem,
         showImage: Binding<Bool> = .constant(true),
         onItemRemoveTapped: (() -> Void)? = nil,
         onCancelLoading: (() -> Void)? = nil) {
        self.cartItem = cartItem
        self._showProductImage = showImage
        self.onItemRemoveTapped = onItemRemoveTapped
        self.onCancelLoading = onCancelLoading
    }

    var body: some View {
        itemRow
            .padding(.horizontal, Constants.horizontalPadding)
            .geometryGroup()
            .accessibilityLabel(accessibilityLabel)
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
        HStack(spacing: Constants.horizontalElementSpacing) {
            productImage
                .frame(width: dimension)
                .frame(minHeight: dimension)

            VStack(alignment: .leading, spacing: Constants.itemTitleAndPriceSpacing * (1 / scale)) {
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
            }
            .multilineTextAlignment(.leading)
            .lineLimit(Constants.titleSubtitleLineLimit)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, showProductImage ? 0 : Constants.cardContentHorizontalPadding * (1 / scale))
            .padding(.vertical, Constants.verticalPadding * (1 / scale))
            if let onItemRemoveTapped {
                CartRowRemoveButton {
                    onItemRemoveTapped()
                }
            }
        }
        .padding(.trailing, Constants.cardContentHorizontalPadding)
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
            [cartItem.title, cartItem.subtitle, cartItem.formattedPrice]
                .compactMap { $0 }
                .joined(separator: ",")
        }
    }
}

private extension ItemRowView {
    enum Constants {
        static let productCardSize: CGFloat = 96
        static let maximumProductCardSize: CGFloat = Self.productCardSize * 1.5
        static let horizontalPadding: CGFloat = POSPadding.medium
        static let verticalPadding: CGFloat = POSPadding.small
        static let horizontalElementSpacing: CGFloat = POSSpacing.medium
        static let cardContentHorizontalPadding: CGFloat = POSPadding.medium
        static let itemTitleAndPriceSpacing: CGFloat = POSSpacing.xSmall
        static let itemTitleFont: POSFontStyle = .posBodySmallBold()
        static let itemSubtitleFont: POSFontStyle = .posBodySmallRegular()
        static let itemPriceFont: POSFontStyle = .posBodySmallRegular()
        static let titleSubtitleLineLimit: Int = 4

        static let cartConfiguration = GhostItemCardViewConfiguration(
            placeholderHeight: 24,
            cardSize: Constants.productCardSize,
            maximumCardSize: Constants.maximumProductCardSize,
            topPlaceholderWidthMultiplier: 0.4,
            bottomPlaceholderWidthMultiplier: 0.35,
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
