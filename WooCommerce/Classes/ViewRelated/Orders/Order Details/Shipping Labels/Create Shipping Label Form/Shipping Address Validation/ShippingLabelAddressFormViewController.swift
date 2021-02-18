import UIKit
import Yosemite

final class ShippingLabelAddressFormViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var confirmButton: UIButton!

    private let viewModel: ShippingLabelAddressFormViewModel

    /// Needed to scroll content to a visible area when the keyboard appears.
    ///
    private lazy var keyboardFrameObserver = KeyboardFrameObserver(onKeyboardFrameUpdate: { [weak self] frame in
        self?.handleKeyboardFrameUpdate(keyboardFrame: frame)
    })

    /// Init
    ///
    init(type: ShipType, address: ShippingLabelAddress?) {
        viewModel = ShippingLabelAddressFormViewModel(type: type, address: address)
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
        configureConfirmButton()
        keyboardFrameObserver.startObservingKeyboardFrame(sendInitialEvent: true)
    }
}

// MARK: - View Configuration
//
private extension ShippingLabelAddressFormViewController {

    func configureNavigationBar() {
        title = viewModel.type == .origin ? Localization.titleViewShipFrom : Localization.titleViewShipTo
        removeNavigationBackBarButtonText()
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground
        tableView.separatorStyle = .singleLine
        tableView.removeLastCellSeparator()

        registerTableViewCells()

        tableView.dataSource = self
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }

    func configureConfirmButton() {
        confirmButton.setTitle(Localization.confirmButtonTitle, for: .normal)
        // TODO: implement confirm button action
        //confirmButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        confirmButton.applySecondaryButtonStyle()
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ShippingLabelAddressFormViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.type.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - Cell configuration
//
private extension ShippingLabelAddressFormViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TitleAndTextFieldTableViewCell where row == .name:
            configureName(cell: cell, row: row)
        case let cell as TitleAndTextFieldTableViewCell where row == .company:
            configureCompany(cell: cell, row: row)
        case let cell as TitleAndTextFieldTableViewCell where row == .phone:
            configurePhone(cell: cell, row: row)
        case let cell as TitleAndTextFieldTableViewCell where row == .address:
            configureAddress(cell: cell, row: row)
        case let cell as TitleAndTextFieldTableViewCell where row == .address2:
            configureAddress2(cell: cell, row: row)
        case let cell as TitleAndTextFieldTableViewCell where row == .city:
            configureCity(cell: cell, row: row)
        case let cell as TitleAndTextFieldTableViewCell where row == .postcode:
            configurePostcode(cell: cell, row: row)
        case let cell as TitleAndTextFieldTableViewCell where row == .state:
            configureState(cell: cell, row: row)
        case let cell as TitleAndTextFieldTableViewCell where row == .country:
            configureCountry(cell: cell, row: row)
        default:
            fatalError("Cannot instantiate \(cell) with row \(row.type)")
            break
        }
    }

    func configureName(cell: TitleAndTextFieldTableViewCell, row: Row) {
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.nameField,
                                                                     text: viewModel.address?.name,
                                                                     placeholder: Localization.nameFieldPlaceholder,
                                                                     state: .normal,
                                                                     keyboardType: .default,
                                                                     textFieldAlignment: .leading) { (newText) in

        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureCompany(cell: TitleAndTextFieldTableViewCell, row: Row) {
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.companyField,
                                                                     text: viewModel.address?.company,
                                                                     placeholder: Localization.companyFieldPlaceholder,
                                                                     state: .normal,
                                                                     keyboardType: .default,
                                                                     textFieldAlignment: .leading) { (newText) in

        }
        cell.configure(viewModel: cellViewModel)
    }

    func configurePhone(cell: TitleAndTextFieldTableViewCell, row: Row) {
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.phoneField,
                                                                     text: viewModel.address?.phone,
                                                                     placeholder: Localization.phoneFieldPlaceholder,
                                                                     state: .normal,
                                                                     keyboardType: .default,
                                                                     textFieldAlignment: .leading) { (newText) in

        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureAddress(cell: TitleAndTextFieldTableViewCell, row: Row) {
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.addressField,
                                                                     text: viewModel.address?.address1,
                                                                     placeholder: Localization.addressFieldPlaceholder,
                                                                     state: .normal,
                                                                     keyboardType: .default,
                                                                     textFieldAlignment: .leading) { (newText) in

        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureAddress2(cell: TitleAndTextFieldTableViewCell, row: Row) {
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.address2Field,
                                                                     text: viewModel.address?.address2,
                                                                     placeholder: Localization.address2FieldPlaceholder,
                                                                     state: .normal,
                                                                     keyboardType: .default,
                                                                     textFieldAlignment: .leading) { (newText) in

        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureCity(cell: TitleAndTextFieldTableViewCell, row: Row) {
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.cityField,
                                                                     text: viewModel.address?.city,
                                                                     placeholder: Localization.cityFieldPlaceholder,
                                                                     state: .normal,
                                                                     keyboardType: .default,
                                                                     textFieldAlignment: .leading) { (newText) in

        }
        cell.configure(viewModel: cellViewModel)
    }

    func configurePostcode(cell: TitleAndTextFieldTableViewCell, row: Row) {
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.postcodeField,
                                                                     text: viewModel.address?.postcode,
                                                                     placeholder: Localization.postcodeFieldPlaceholder,
                                                                     state: .normal,
                                                                     keyboardType: .default,
                                                                     textFieldAlignment: .leading) { (newText) in

        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureState(cell: TitleAndTextFieldTableViewCell, row: Row) {
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.stateField,
                                                                     text: viewModel.address?.state,
                                                                     placeholder: Localization.stateFieldPlaceholder,
                                                                     state: .normal,
                                                                     keyboardType: .default,
                                                                     textFieldAlignment: .leading) { (newText) in

        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureCountry(cell: TitleAndTextFieldTableViewCell, row: Row) {
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.countryField,
                                                                     text: viewModel.address?.country,
                                                                     placeholder: Localization.countryFieldPlaceholder,
                                                                     state: .normal,
                                                                     keyboardType: .default,
                                                                     textFieldAlignment: .leading) { (newText) in

        }
        cell.configure(viewModel: cellViewModel)
    }
}

// MARK: KeyboardScrollable
extension ShippingLabelAddressFormViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        tableView
    }
}

extension ShippingLabelAddressFormViewController {

    struct Section: Equatable {
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case topBanner

        case name
        case company
        case phone
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
            case .name, .company, .phone, .address, .address2, .city, .postcode, .state, .country:
                return TitleAndTextFieldTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

private extension ShippingLabelAddressFormViewController {
    enum Localization {
        static let titleViewShipFrom = NSLocalizedString("Ship from", comment: "Shipping Label Address Validation navigation title")
        static let titleViewShipTo = NSLocalizedString("Ship to", comment: "Shipping Label Address Validation navigation title")

        static let nameField = NSLocalizedString("Name", comment: "Text field name in Shipping Label Address Validation")
        static let nameFieldPlaceholder = NSLocalizedString("Required", comment: "Text field placeholder in Shipping Label Address Validation")
        static let companyField = NSLocalizedString("Company", comment: "Text field company in Shipping Label Address Validation")
        static let companyFieldPlaceholder = NSLocalizedString("Optional", comment: "Text field placeholder in Shipping Label Address Validation")
        static let phoneField = NSLocalizedString("Phone", comment: "Text field phone in Shipping Label Address Validation")
        static let phoneFieldPlaceholder = NSLocalizedString("Optional", comment: "Text field placeholder in Shipping Label Address Validation")
        static let addressField = NSLocalizedString("Address", comment: "Text field address in Shipping Label Address Validation")
        static let addressFieldPlaceholder = NSLocalizedString("Required", comment: "Text field placeholder in Shipping Label Address Validation")
        static let address2Field = NSLocalizedString("Address 2", comment: "Text field address 2 in Shipping Label Address Validation")
        static let address2FieldPlaceholder = NSLocalizedString("Optional", comment: "Text field placeholder in Shipping Label Address Validation")
        static let cityField = NSLocalizedString("City", comment: "Text field city in Shipping Label Address Validation")
        static let cityFieldPlaceholder = NSLocalizedString("Required", comment: "Text field placeholder in Shipping Label Address Validation")
        static let postcodeField = NSLocalizedString("Postcode", comment: "Text field postcode in Shipping Label Address Validation")
        static let postcodeFieldPlaceholder = NSLocalizedString("Required", comment: "Text field placeholder in Shipping Label Address Validation")
        static let stateField = NSLocalizedString("State", comment: "Text field state in Shipping Label Address Validation")
        static let stateFieldPlaceholder = NSLocalizedString("Required", comment: "Text field placeholder in Shipping Label Address Validation")
        static let countryField = NSLocalizedString("Country", comment: "Text field country in Shipping Label Address Validation")
        static let countryFieldPlaceholder = NSLocalizedString("Required", comment: "Text field placeholder in Shipping Label Address Validation")

        static let confirmButtonTitle = NSLocalizedString("Use Address as Entered",
                                                          comment: "Action to use the address in Shipping Label Validation screen as entered")
    }
}
