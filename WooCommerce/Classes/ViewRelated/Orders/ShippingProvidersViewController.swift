import UIKit

final class ShippingProvidersViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
    }
}


// MARK : - Navigation bar
//
private extension ShippingProvidersViewController {
    func configureNavigation() {
        configureTitle()
    }

    func configureTitle() {
        title = NSLocalizedString("Shipping Providers",
                                  comment: "Title of view displaying all available Shipment Tracking Providers")
    }
}
