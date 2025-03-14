import SwiftUI
import struct Yosemite.POSCoupon

struct CouponCardView: View {
    private let coupon: POSCoupon

    init(coupon: POSCoupon) {
        self.coupon = coupon
    }

    var body: some View {
        HStack {
            Text(coupon.id.uuidString)
            Text(coupon.couponID.description)
        }
    }
}
