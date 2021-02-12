import UIKit
import Yosemite

final class ShippingLabelAddressValidationViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let viewModel: ShippingLabelAddressValidationViewModel

    /// Init
    ///
    init(addressVerification: ShippingLabelAddressVerification) {
        viewModel = ShippingLabelAddressValidationViewModel(addressVerification: addressVerification)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureMainView()
        configureTableView()
        registerTableViewCells()
    }
}

// MARK: - View Configuration
//
private extension ShippingLabelAddressValidationViewController {

    func configureNavigationBar() {
        title = viewModel.addressVerification.type == .origin ? Localization.titleViewShipFrom : Localization.titleViewShipTo
        removeNavigationBackBarButtonText()
    }

    func configureMainView() {
        view.backgroundColor = .listForeground
    }

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listForeground
        tableView.separatorStyle = .none

        registerTableViewCells()

        //tableView.dataSource = self
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }
}

extension ShippingLabelAddressValidationViewController {

    struct Section: Equatable {
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case topBanner

        case name
        case company
        case phones
        case address
        case address2
        case city
        case postcode
        case state
        case country

        case fieldError

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .topBanner, .fieldError:
                return BasicTableViewCell.self
            case .name, .company, .phones, .address, .address2, .city, .postcode, .state, .country:
                return TitleAndTextFieldTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

private extension ShippingLabelAddressValidationViewController {
    enum Localization {
        static let titleViewShipFrom = NSLocalizedString("Ship from", comment: "Shipping Label Address Validation navigation title")
        static let titleViewShipTo = NSLocalizedString("Ship to", comment: "Shipping Label Address Validation navigation title")
    }
}
