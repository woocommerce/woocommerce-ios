import SwiftUI
import struct Yosemite.POSRefundItem

/// A reusable row displaying a refunded product with image, name, quantity × price, and refund total.
struct POSRefundedProductRowView: View {
    let item: POSRefundItem
    var accessibilityLabel: String?

    var body: some View {
        HStack(alignment: .center, spacing: POSSpacing.medium) {
            if item.isLumpSum {
                CustomAmountAvatar(name: item.name)
                    .frame(width: Constants.imageSize, height: Constants.imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
            } else {
                POSItemImageView(imageSource: item.imageSrc, imageSize: Constants.imageSize, scale: 1)
                    .frame(width: Constants.imageSize, height: Constants.imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
            }

            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                Text(item.name)
                    .font(.posBodyLargeBold)
                    .foregroundStyle(Color.posOnSurface)
                    .fixedSize(horizontal: false, vertical: true)

                if !item.isLumpSum {
                    Text(Localization.quantityLabel(item.quantity.intValue, item.formattedPrice))
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                }
            }

            Spacer()

            Text(item.formattedTotal)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurface)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel ?? defaultAccessibilityLabel)
    }

    private var defaultAccessibilityLabel: String {
        if item.isLumpSum {
            return Localization.lumpSumAccessibilityLabel(name: item.name, total: item.formattedTotal)
        }
        return Localization.defaultAccessibilityLabel(
            name: item.name,
            quantity: "\(item.quantity.intValue)",
            price: item.formattedPrice,
            total: item.formattedTotal
        )
    }
}

private enum Constants {
    static let imageSize: CGFloat = 56
}

private enum Localization {
    static func quantityLabel(_ quantity: Int, _ unitPrice: String) -> String {
        let format = NSLocalizedString(
            "pos.refundedProductRow.quantityLabel",
            value: "%1$d × %2$@",
            comment: "Product quantity and price label. %1$d is the quantity, %2$@ is the unit price."
        )
        return String(format: format, quantity, unitPrice)
    }

    static func defaultAccessibilityLabel(name: String, quantity: String, price: String, total: String) -> String {
        let format = NSLocalizedString(
            "pos.refundedProductRow.accessibilityLabel",
            value: "%1$@, Quantity: %2$@ at %3$@ each, Refunded %4$@",
            comment: "Accessibility label for refunded product row. " +
            "%1$@ is product name, %2$@ is quantity, %3$@ is unit price, %4$@ is refund total."
        )
        return String(format: format, name, quantity, price, total)
    }

    static func lumpSumAccessibilityLabel(name: String, total: String) -> String {
        let format = NSLocalizedString(
            "pos.refundedProductRow.lumpSumAccessibilityLabel",
            value: "%1$@, Refunded %2$@",
            comment: "Accessibility label for refunded custom amount/fee row. " +
            "%1$@ is the custom amount name, %2$@ is the refund total."
        )
        return String(format: format, name, total)
    }
}
