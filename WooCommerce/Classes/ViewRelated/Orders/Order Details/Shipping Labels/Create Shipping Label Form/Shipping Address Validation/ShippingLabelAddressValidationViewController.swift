import UIKit
import Yosemite

final class ShippingLabelAddressValidationViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let viewModel: ShippingLabelAddressValidationViewModel
    
    /// Init
    ///
    init(address: ShippingLabelAddress) {
        viewModel = ShippingLabelAddressValidationViewModel(address: address)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }
}
