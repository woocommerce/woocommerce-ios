import SwiftUI
import struct Yosemite.POSSimpleProduct
import struct Yosemite.POSVariation

struct ItemRowView: View {
    private let cartItem: Cart.PurchasableItem
    private let onItemRemoveTapped: (() -> Void)?
    private let onCancelLoading: (() -> Void)?
    private let billingEmail: String?
    private let onSetEmailTapped: (() -> Void)?
    private let giftCardInfo: GiftCardInfo?
    private let onSetGiftCardInfoTapped: (() -> Void)?

    @ScaledMetric private var scale: CGFloat = 1.0
    @Binding private var showProductImage: Bool

    private var dimension: CGFloat {
        min(Constants.productCardSize * scale, Constants.maximumProductCardSize)
    }

    /// Whether this cart item is a downloadable product
    private var isDownloadable: Bool {
        guard case .loaded(let orderableItem) = cartItem.state else { return false }
        if let simpleProduct = orderableItem as? POSSimpleProduct {
            return simpleProduct.downloadable
        } else if let variation = orderableItem as? POSVariation {
            return variation.downloadable
        }
        return false
    }

    /// Whether this cart item is a gift card product
    private var isGiftCard: Bool {
        guard case .loaded(let orderableItem) = cartItem.state else { return false }
        if let simpleProduct = orderableItem as? POSSimpleProduct {
            return simpleProduct.isGiftCard
        } else if let variation = orderableItem as? POSVariation {
            return variation.isGiftCard
        }
        return false
    }

    init(cartItem: Cart.PurchasableItem,
         showImage: Binding<Bool> = .constant(true),
         onItemRemoveTapped: (() -> Void)? = nil,
         onCancelLoading: (() -> Void)? = nil,
         billingEmail: String? = nil,
         onSetEmailTapped: (() -> Void)? = nil,
         giftCardInfo: GiftCardInfo? = nil,
         onSetGiftCardInfoTapped: (() -> Void)? = nil) {
        self.cartItem = cartItem
        self._showProductImage = showImage
        self.onItemRemoveTapped = onItemRemoveTapped
        self.onCancelLoading = onCancelLoading
        self.billingEmail = billingEmail
        self.onSetEmailTapped = onSetEmailTapped
        self.giftCardInfo = giftCardInfo
        self.onSetGiftCardInfoTapped = onSetGiftCardInfoTapped
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

                // Show email recipient info for downloadable items
                if isDownloadable {
                    downloadableEmailRow
                }

                // Show gift card info for gift card items
                if isGiftCard {
                    giftCardInfoRow
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

    /// Shows the email recipient for downloadable products, or a button to set it
    @ViewBuilder
    private var downloadableEmailRow: some View {
        HStack(spacing: POSSpacing.xSmall) {
            Image(systemName: "envelope")
                .font(.posBodySmallRegular())
                .foregroundColor(.posOnSurfaceVariantLowest)

            if let email = billingEmail, !email.isEmpty {
                Text(email)
                    .font(.posBodySmallRegular())
                    .foregroundColor(.posOnSurfaceVariantLowest)
                    .lineLimit(1)
            }

            if let onSetEmailTapped {
                Button {
                    onSetEmailTapped()
                } label: {
                    Text(billingEmail?.isEmpty ?? true ? Localization.setEmail : Localization.changeEmail)
                        .font(.posBodySmallRegular())
                        .foregroundColor(.posPrimary)
                }
            }
        }
    }

    /// Shows the gift card recipient/sender info, or a button to set it
    @ViewBuilder
    private var giftCardInfoRow: some View {
        HStack(spacing: POSSpacing.xSmall) {
            Image(systemName: "gift")
                .font(.posBodySmallRegular())
                .foregroundColor(.posOnSurfaceVariantLowest)

            if let info = giftCardInfo {
                Text(Localization.giftCardInfoSummary(recipient: info.recipientEmail, sender: info.senderName))
                    .font(.posBodySmallRegular())
                    .foregroundColor(.posOnSurfaceVariantLowest)
                    .lineLimit(1)
            }

            if let onSetGiftCardInfoTapped {
                Button {
                    onSetGiftCardInfoTapped()
                } label: {
                    Text(giftCardInfo == nil ? Localization.setGiftCardDetails : Localization.changeGiftCardDetails)
                        .font(.posBodySmallRegular())
                        .foregroundColor(.posPrimary)
                }
            }
        }
    }
}

private extension ItemRowView {
    enum Localization {
        static let setEmail = NSLocalizedString(
            "pos.itemRow.downloadable.setEmail",
            value: "Set recipient",
            comment: "Button to set the email recipient for a downloadable product in POS cart"
        )
        static let changeEmail = NSLocalizedString(
            "pos.itemRow.downloadable.changeEmail",
            value: "Change",
            comment: "Button to change the email recipient for a downloadable product in POS cart"
        )
        static let setGiftCardDetails = NSLocalizedString(
            "pos.itemRow.giftCard.setDetails",
            value: "Set details",
            comment: "Button to set the recipient and sender details for a gift card in POS cart"
        )
        static let changeGiftCardDetails = NSLocalizedString(
            "pos.itemRow.giftCard.changeDetails",
            value: "Change",
            comment: "Button to change the recipient and sender details for a gift card in POS cart"
        )

        static func giftCardInfoSummary(recipient: String, sender: String) -> String {
            String(format: NSLocalizedString(
                "pos.itemRow.giftCard.summary",
                value: "To: %@ from %@",
                comment: "Summary of gift card recipient and sender. %1$@ is the recipient email, %2$@ is the sender name"
            ), recipient, sender)
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
