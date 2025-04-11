import struct Yosemite.POSCoupon
import SwiftUI

struct CouponCardView: View {
    private let coupon: POSCoupon

    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var dimension: CGFloat {
        min(Constants.productCardSize * scale, Constants.maximumProductCardSize)
    }

    init(coupon: POSCoupon) {
        self.coupon = coupon
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            POSCouponImageView(size: dimension)

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(coupon.code)
                    .foregroundStyle(Constants.titleColor)
                    .multilineTextAlignment(.leading)
                    .font(Constants.itemTitleFont)

                Text(coupon.summary)
                    .foregroundStyle(Constants.detailColor)
                    .font(Constants.itemDetailFont)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Constants.horizontalTextPadding * (1 / scale))
            .padding(.vertical, Constants.verticalTextPadding * (1 / scale))
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: dimension)
        .background(Constants.backgroundColor)
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
