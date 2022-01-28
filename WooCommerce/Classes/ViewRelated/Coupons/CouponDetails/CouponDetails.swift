import SwiftUI
import Yosemite

struct CouponDetails: View {
    @ObservedObject private var viewModel: CouponDetailsViewModel

    init(viewModel: CouponDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(Localization.detailSectionTitle)
                    .bold()
                    .padding(Constants.margin)
                Divider()
                    .padding(.leading, Constants.margin)
                TitleAndValueRow(title: Localization.couponCode,
                                 value: .content(viewModel.couponCode),
                                 selectable: true) {}
            }
            .background(Color(.listForeground))
        }
        .background(Color(.listBackground))
        .navigationTitle(Localization.navigationTitle)
    }
}

private extension CouponDetails {
    enum Constants {
        static let margin: CGFloat = 16
    }

    enum Localization {
        static let navigationTitle = NSLocalizedString("Coupon", comment: "Title of Coupon Details screen")
        static let detailSectionTitle = NSLocalizedString("Coupon Details", comment: "Title of Details section in Coupon Details screen")
        static let couponCode = NSLocalizedString("Coupon Code", comment: "Title of the Coupon Code row in Coupon Details screen")
    }
}

struct CouponDetails_Previews: PreviewProvider {
    static var previews: some View {
        CouponDetails(viewModel: CouponDetailsViewModel(coupon: Coupon.sampleCoupon))
    }
}
