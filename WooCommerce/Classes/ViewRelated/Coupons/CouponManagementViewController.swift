import UIKit

class CouponManagementViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
    }
}

// MARK: - View Configuration
//
private extension CouponManagementViewController {

    func configureNavigation() {
        title = NSLocalizedString("Coupons", comment: "Coupon management coupon list screen title")
    }
}
