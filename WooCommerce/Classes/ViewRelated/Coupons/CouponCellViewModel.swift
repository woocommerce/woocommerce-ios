import Yosemite

typealias CouponCellViewModel = TitleAndSubtitleAndStatusTableViewCell.ViewModel

extension CouponCellViewModel {
    static func build(from coupon: Coupon) -> CouponCellViewModel {
        CouponCellViewModel(id: "\(coupon.couponID)",
                      title: coupon.code,
                      subtitle: coupon.summary(),
                      accessibilityLabel: coupon.description.isNotEmpty ? coupon.description : coupon.code,
                      status: coupon.expiryStatus().localizedName,
                      statusBackgroundColor: coupon.expiryStatus().statusBackgroundColor)
    }
}
