import SwiftUI
import struct Yosemite.POSOrderItem
import struct Yosemite.OrderItemAttribute

/// Read-only list of order line items shown alongside the payment view during booking checkout.
/// Mirrors the cart panel layout used in the regular POS checkout flow.
struct POSBookingOrderItemsView: View {
    let lineItems: [POSOrderItem]
    let formattedSubtotal: String
    let formattedTax: String
    let formattedTotal: String

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(title: Localization.orderItemsTitle)

            if lineItems.isEmpty {
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: POSSpacing.medium) {
                        ForEach(lineItems, id: \.itemID) { item in
                            BookingOrderItemRowView(item: item)
                        }
                    }
                    .padding(.bottom, POSPadding.large)
                }

                totalsSection
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.posSurfaceBright.ignoresSafeArea(.all))
    }

    // MARK: - Totals

    private var totalsSection: some View {
        VStack(spacing: POSSpacing.small) {
            Divider()
                .overlay(Color.posOutlineVariant)

            VStack(spacing: POSSpacing.xSmall) {
                totalsRow(label: Localization.subtotal, value: formattedSubtotal)
                totalsRow(label: Localization.taxes, value: formattedTax)
            }
            .padding(.horizontal, POSPadding.medium)
            .padding(.vertical, POSPadding.small)

            Divider()
                .overlay(Color.posOutlineVariant)

            HStack {
                Text(Localization.total)
                    .font(.posBodyLargeBold)
                Spacer()
                Text(formattedTotal)
                    .font(.posBodyLargeBold)
            }
            .foregroundStyle(Color.posOnSurface)
            .padding(.horizontal, POSPadding.medium)
            .padding(.vertical, POSPadding.small)
        }
        .accessibilityElement(children: .combine)
    }

    private func totalsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
            Spacer()
            Text(value)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurface)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Item Row

/// A single read-only order item row, styled to match the cart's item cards.
private struct BookingOrderItemRowView: View {
    let item: POSOrderItem

    @ScaledMetric private var scale: CGFloat = 1.0

    private var dimension: CGFloat {
        min(Constants.imageSize * scale, Constants.maximumImageSize)
    }

    var body: some View {
        HStack(spacing: POSSpacing.medium) {
            POSItemImageView(imageSource: item.imageSrc,
                             imageSize: dimension,
                             scale: 1)
                .frame(width: dimension)
                .frame(minHeight: dimension)

            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                Text(item.name)
                    .font(.posBodySmallBold())
                    .foregroundStyle(Color.posOnSurface)

                if !item.attributes.isEmpty {
                    Text(item.attributes.map { "\($0.name): \($0.value)" }.joined(separator: ", "))
                        .font(.posBodySmallRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                }

                Text(quantityLabel)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
            }
            .multilineTextAlignment(.leading)
            .lineLimit(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, POSPadding.small)
        }
        .padding(.trailing, POSPadding.medium)
        .padding(.horizontal, POSPadding.medium)
        .frame(maxWidth: .infinity, minHeight: dimension, alignment: .leading)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var quantityLabel: String {
        let quantity = item.quantity.intValue
        if quantity > 1 {
            return String(format: Localization.quantityAndPrice, quantity, item.formattedPrice)
        }
        return item.formattedPrice
    }

    private var accessibilityLabel: String {
        [item.name, quantityLabel, item.formattedTotal]
            .joined(separator: ", ")
    }

    private enum Constants {
        static let imageSize: CGFloat = 96
        static let maximumImageSize: CGFloat = 144
    }

    private enum Localization {
        static let quantityAndPrice = NSLocalizedString(
            "pos.bookingOrderItems.quantityAndPrice",
            value: "%1$d × %2$@",
            comment: "Quantity and unit price for an order item in the booking payment view. %1$d is the quantity, %2$@ is the formatted unit price."
        )
    }
}

// MARK: - Localization

private extension POSBookingOrderItemsView {
    enum Localization {
        static let orderItemsTitle = NSLocalizedString(
            "pos.bookingOrderItems.title",
            value: "Order items",
            comment: "Title for the order items panel shown during booking payment."
        )

        static let subtotal = NSLocalizedString(
            "pos.bookingOrderItems.subtotal",
            value: "Subtotal",
            comment: "Label for the subtotal row in the booking payment order items panel."
        )

        static let taxes = NSLocalizedString(
            "pos.bookingOrderItems.taxes",
            value: "Taxes",
            comment: "Label for the taxes row in the booking payment order items panel."
        )

        static let total = NSLocalizedString(
            "pos.bookingOrderItems.total",
            value: "Total",
            comment: "Label for the total row in the booking payment order items panel."
        )
    }
}

// MARK: - Previews

#if DEBUG
import struct Yosemite.POSOrder

#Preview("Booking Order Items") {
    POSBookingOrderItemsView(
        lineItems: [
            POSOrderItem(itemID: 1,
                         name: "Premium Coffee Beans",
                         quantity: 2,
                         price: 15.00,
                         total: 30.00,
                         totalTax: 2.40,
                         formattedPrice: "$15.00",
                         formattedTotal: "$30.00",
                         imageSrc: nil,
                         attributes: []),
            POSOrderItem(itemID: 2,
                         name: "Organic Earl Grey Tea",
                         quantity: 1,
                         price: 12.50,
                         total: 12.50,
                         totalTax: 1.00,
                         formattedPrice: "$12.50",
                         formattedTotal: "$12.50",
                         imageSrc: nil,
                         attributes: [OrderItemAttribute(metaID: 1, name: "Size", value: "Large")])
        ],
        formattedSubtotal: "$42.50",
        formattedTax: "$3.40",
        formattedTotal: "$45.90"
    )
    .frame(width: 400)
}
#endif
