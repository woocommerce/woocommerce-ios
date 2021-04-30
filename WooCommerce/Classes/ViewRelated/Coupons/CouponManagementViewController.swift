import UIKit

final class CouponManagementViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
    }
}

// MARK: - View Configuration
//
private extension CouponManagementViewController {

    func configureNavigation() {
        title = Localization.title
    }
}

// MARK: - Localization
//
private extension CouponManagementViewController {
    enum Localization {
        static let title = NSLocalizedString("Coupons", comment: "Coupon management coupon list screen title")
    }
}
