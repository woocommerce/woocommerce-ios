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


extension ShippingLabelAddressValidationViewController {

    struct Section: Equatable {
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case errorBanner

        case name
        case company
        case phones
        case address
        case address2
        case city
        case postcode
        case state
        case country

        case useAddressAsEntered

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .errorBanner:
                return BasicTableViewCell.self
            case .name, .company, .phones, .address, .address2, .city, .postcode, .state, .country:
                return NumberOfLinkedProductsTableViewCell.self
            case .useAddressAsEntered:
                return ButtonTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}
