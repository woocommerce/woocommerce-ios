import SwiftUI
import Yosemite

struct CouponDetails: View {
    @ObservedObject private var viewModel: CouponDetailsViewModel

    init(viewModel: CouponDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct CouponDetails_Previews: PreviewProvider {
    static var previews: some View {
        CouponDetails(viewModel: CouponDetailsViewModel(coupon: Coupon.sampleCoupon))
    }
}
