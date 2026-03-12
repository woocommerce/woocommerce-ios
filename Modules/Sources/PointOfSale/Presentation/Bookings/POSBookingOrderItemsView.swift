import SwiftUI
import struct Yosemite.POSBooking
import struct Yosemite.POSOrderItem
import struct Yosemite.OrderItemAttribute

/// Read-only list of order line items shown alongside the payment view during booking checkout.
/// Mirrors the cart panel layout used in the regular POS checkout flow.
struct POSBookingOrderItemsView: View {
    let booking: POSBooking
    let bookingsByOrderItemID: [Int64: POSBooking]

    private var lineItems: [POSOrderItem] {
        booking.order.lineItems
    }

    private var itemCount: Int {
        lineItems.count
    }

    var body: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(title: Localization.cartTitle,
                              trailingContent: {
                if let itemsLabel = itemsInCartLabel {
                    Text(itemsLabel)
                        .font(Constants.itemsFont)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        .foregroundColor(Color.posOnSurfaceVariantLowest)
                }
            })

            if lineItems.isEmpty {
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: Constants.cartItemSpacing) {
                        ForEach(lineItems, id: \.itemID) { item in
                            BookingOrderItemRowView(
                                item: item,
                                booking: bookingsByOrderItemID[item.itemID]
                            )
                        }
                    }
                    .padding(.bottom, Constants.cartLastItemBottomPadding)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.posSurfaceBright.ignoresSafeArea(.all))
        .accessibilityElement(children: .contain)
    }

    private var itemsInCartLabel: String? {
        guard itemCount > 0 else { return nil }
        return String.pluralize(itemCount,
                                singular: Localization.itemCountSingular,
                                plural: Localization.itemCountPlural)
    }
}

// MARK: - Item Row

/// A single read-only order item row, styled to match the cart's `ItemRowView`.
/// Shows the booking date/time range when the item corresponds to a booking.
private struct BookingOrderItemRowView: View {
    let item: POSOrderItem
    let booking: POSBooking?

    @ScaledMetric private var scale: CGFloat = 1.0

    private var dimension: CGFloat {
        min(Constants.productCardSize * scale, Constants.maximumProductCardSize)
    }

    var body: some View {
        productRow
            .padding(.horizontal, Constants.horizontalPadding)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
    }

    private var productRow: some View {
        HStack(spacing: Constants.horizontalElementSpacing) {
            POSItemImageView(imageSource: item.imageSrc,
                             imageSize: dimension,
                             scale: 1)
                .frame(width: dimension)
                .frame(minHeight: dimension)

            VStack(alignment: .leading, spacing: Constants.itemTitleAndPriceSpacing * (1 / scale)) {
                Text(item.name)
                    .foregroundColor(PointOfSaleItemListCardConstants.titleColor)
                    .font(Constants.itemTitleFont)

                if let timeRange = bookingTimeRange {
                    Text(timeRange)
                        .foregroundColor(PointOfSaleItemListCardConstants.detailColor)
                        .font(Constants.itemSubtitleFont)
                }

                if !item.attributes.isEmpty {
                    Text(item.attributes.map { "\($0.name): \($0.value)" }.joined(separator: ", "))
                        .foregroundColor(PointOfSaleItemListCardConstants.detailColor)
                        .font(Constants.itemSubtitleFont)
                }

                Text(priceLabel)
                    .foregroundColor(PointOfSaleItemListCardConstants.detailColor)
                    .font(Constants.itemPriceFont)
            }
            .multilineTextAlignment(.leading)
            .lineLimit(Constants.titleSubtitleLineLimit)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Constants.verticalPadding * (1 / scale))
        }
        .padding(.trailing, Constants.cardContentHorizontalPadding)
        .frame(maxWidth: .infinity, minHeight: dimension, alignment: .leading)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
    }

    private var bookingTimeRange: String? {
        guard let booking else { return nil }
        return POSBookingDateFormatter.formattedTimeRange(for: booking)
    }

    private var priceLabel: String {
        let quantity = item.quantity.intValue
        if quantity > 1 {
            return String(format: Localization.quantityAndPrice, quantity, item.formattedPrice)
        }
        return item.formattedPrice
    }

    private var accessibilityLabel: String {
        [item.name, bookingTimeRange, priceLabel]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

// MARK: - Constants

/// Matches the constants used by `CartView` and `ItemRowView` for consistent styling.
private enum Constants {
    static let itemsFont: POSFontStyle = .posBodySmallRegular()
    static let cartItemSpacing: CGFloat = POSSpacing.medium
    static let cartLastItemBottomPadding: CGFloat = POSPadding.large

    // ItemRowView constants
    static let productCardSize: CGFloat = 96
    static let maximumProductCardSize: CGFloat = productCardSize * 1.5
    static let horizontalPadding: CGFloat = POSPadding.medium
    static let verticalPadding: CGFloat = POSPadding.small
    static let horizontalElementSpacing: CGFloat = POSSpacing.medium
    static let cardContentHorizontalPadding: CGFloat = POSPadding.medium
    static let itemTitleAndPriceSpacing: CGFloat = POSSpacing.xSmall
    static let itemTitleFont: POSFontStyle = .posBodySmallBold()
    static let itemSubtitleFont: POSFontStyle = .posBodySmallRegular()
    static let itemPriceFont: POSFontStyle = .posBodySmallRegular()
    static let titleSubtitleLineLimit: Int = 4
}

// MARK: - Localization

private enum Localization {
    static let cartTitle = NSLocalizedString(
        "pos.bookingOrderItems.cartTitle",
        value: "Cart",
        comment: "Title at the header for the order items panel during booking payment."
    )

    static let itemCountSingular = NSLocalizedString(
        "pos.bookingOrderItems.itemCount.singular",
        value: "%1$d item",
        comment: "Singular item count shown in the header of the booking payment order items panel. %1$d is the number of items."
    )

    static let itemCountPlural = NSLocalizedString(
        "pos.bookingOrderItems.itemCount.plural",
        value: "%1$d items",
        comment: "Plural item count shown in the header of the booking payment order items panel. %1$d is the number of items."
    )

    static let quantityAndPrice = NSLocalizedString(
        "pos.bookingOrderItems.quantityAndPrice",
        value: "%1$d × %2$@",
        comment: "Quantity and unit price for an order item in the booking payment view. %1$d is the quantity, %2$@ is the formatted unit price."
    )
}

// MARK: - Previews

#if DEBUG
#Preview("Booking Order Items") {
    POSBookingOrderItemsView(
        booking: POSPreviewHelpers.makePreviewUnpaidBooking(),
        bookingsByOrderItemID: [:]
    )
    .frame(width: 400)
}
#endif
