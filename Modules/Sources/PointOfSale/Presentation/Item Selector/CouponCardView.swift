import struct Yosemite.POSCoupon
import SwiftUI

struct CouponCardView: View {
    private let coupon: POSCoupon

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    private var dimension: CGFloat {
        let baseSize: CGFloat = isCompact ? 56 : Constants.productCardSize
        let maxSize: CGFloat = isCompact ? 84 : Constants.maximumProductCardSize
        return min(baseSize * scale, maxSize)
    }

    private var titleFont: POSFontStyle {
        isCompact ? .posBodySmallBold() : Constants.itemTitleFont
    }

    private var detailFont: POSFontStyle {
        isCompact ? .posBodySmallRegular() : Constants.itemDetailFont
    }

    init(coupon: POSCoupon) {
        self.coupon = coupon
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            POSCouponImageView(size: dimension,
                               state: coupon.isExpired ? .expired : .normal)

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(coupon.code)
                    .foregroundStyle(titleColor)
                    .multilineTextAlignment(.leading)
                    .font(titleFont)

                Text(coupon.summary)
                    .foregroundStyle(summaryColor)
                    .font(detailFont)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)

                if coupon.isExpired, let expirationDate = coupon.dateExpires {
                    Text(formattedExpirationText(date: expirationDate))
                        .foregroundStyle(expirationTextColor)
                        .font(Constants.itemDetailFont)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, (isCompact ? POSPadding.small : Constants.horizontalTextPadding) * (1 / scale))
            .padding(.vertical, (isCompact ? POSPadding.small : Constants.verticalTextPadding) * (1 / scale))
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? nil : dimension)
        .background(cardBackgroundColor)
        .posItemCardBorderStyles()
    }
}

private extension CouponCardView {
    typealias Constants = PointOfSaleItemListCardConstants

    enum Localization {
        static let expirationText = NSLocalizedString(
            "couponCardView.expirationText",
            value: "Expired on %@",
            comment: "Expiration date for a given coupon, displayed in the coupon card. Reads as 'Expired · 18 April 2025'."
        )
    }

    func formattedExpirationText(date: Date) -> String {
        String(format: Localization.expirationText,
               DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none))
    }

    var titleColor: Color {
        coupon.isExpired ? Constants.disabledTitleColor : Constants.titleColor
    }

    var summaryColor: Color {
        coupon.isExpired ? Constants.disabledTitleColor : Constants.detailColor
    }

    var expirationTextColor: Color {
        Constants.disabledTitleColor
    }

    var cardBackgroundColor: Color {
        coupon.isExpired ? Constants.disabledBackgroundColor : Constants.backgroundColor
    }
}

#if DEBUG
#Preview("Coupon states") {
    VStack(spacing: 16) {
        VStack(alignment: .leading) {
            Text("Active Coupon")
                .font(.caption)
                .foregroundStyle(.secondary)
            CouponCardView(coupon: .init(
                id: .init(underlyingType: .coupon, itemID: 1),
                code: "Coupon-123",
                summary: "10% off - All Products"
            ))
        }

        VStack(alignment: .leading) {
            Text("Expired Coupon")
                .font(.caption)
                .foregroundStyle(.secondary)
            CouponCardView(coupon: .init(
                id: .init(underlyingType: .coupon, itemID: 2),
                code: "Old-Coupon-123",
                summary: "10% off - All Products",
                dateExpires: Calendar.current.date(byAdding: .month, value: -1, to: Date())
            ))
        }
    }
    .padding()
}
#endif
