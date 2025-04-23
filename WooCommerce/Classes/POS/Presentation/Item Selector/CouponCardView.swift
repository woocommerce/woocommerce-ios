import struct Yosemite.POSCoupon
import SwiftUI

struct CouponCardView: View {
    private let coupon: POSCoupon
    private let isExpired: Bool

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var dimension: CGFloat {
        min(Constants.productCardSize * scale, Constants.maximumProductCardSize)
    }

    init(coupon: POSCoupon, isExpired: Bool = false) {
        self.coupon = coupon
        self.isExpired = isExpired
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            POSCouponImageView(size: dimension)

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(coupon.code)
                    .foregroundStyle(isExpired ? Constants.disabledTitleColor : Constants.titleColor)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemTitleFont)

                Text(coupon.summary)
                    .foregroundStyle(isExpired ? Constants.disabledTitleColor : Constants.detailColor)
                    .font(Constants.itemDetailFont)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if isExpired, let expirationDate = coupon.dateExpires {
                    // TODO: Date needs formatting
                    Text("Expired . \(expirationDate)")
                        .foregroundStyle(Constants.disabledTitleColor)
                        .font(Constants.itemDetailFont)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, Constants.horizontalTextPadding * (1 / scale))
            .padding(.vertical, Constants.verticalTextPadding * (1 / scale))
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: dimension)
        .background(isExpired ? Constants.disabledBackgroundColor : Constants.backgroundColor)
        .posItemCardBorderStyles()
    }
}

private extension CouponCardView {
    typealias Constants = PointOfSaleItemListCardConstants
}

#if DEBUG
#Preview {
    CouponCardView(coupon: .init(id: .init(),
                                 code: "Coupon-123",
                                 summary: "10% off - All Products"))
}
#endif
