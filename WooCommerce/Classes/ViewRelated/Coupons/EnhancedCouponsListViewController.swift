import Foundation
import UIKit

final class EnhancedCouponsListViewController: UIViewController {
    let couponsListViewController: CouponListViewController

    init(siteID: Int64) {
        couponsListViewController = CouponListViewController(siteID: siteID)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        couponsListViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(couponsListViewController)
        view.addSubview(couponsListViewController.view)
        view.pinSubviewToAllEdges(couponsListViewController.view)
        couponsListViewController.didMove(toParent: self)
    }

}
