import UIKit
import Yosemite

final class ShippingLabelAddressFormViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var confirmButton: UIButton!

    /// Stack view that contains the top warning banner and is contained in the table view header.
    ///
    private lazy var topStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    /// Top banner that shows a warning in case there is an error in the address validation.
    ///
    private lazy var topBannerView: TopBannerView = {
        let topBanner = ShippingLabelAddressTopBannerFactory.addressErrorTopBannerView { [weak self] in
            MapsHelper.openAppleMaps(address: self?.viewModel.address?.formattedPostalAddress) { [weak self] (result) in
                switch result {
                case .success:
                    break
                case .failure:
                    self?.displayAppleMapsErrorNotice()
                }
            }
        } contactCustomerPressed: { [weak self] in
            if PhoneHelper.callPhoneNumber(phone: self?.viewModel.address?.phone) == false {
                self?.displayPhoneNumberErrorNotice()
            }
        }

        topBanner.translatesAutoresizingMaskIntoConstraints = false
        return topBanner
    }()

    private let viewModel: ShippingLabelAddressFormViewModel

    /// Completion callback
    ///
    typealias Completion = (_ address: ShippingLabelAddress?) -> Void
    private let onCompletion: Completion

    /// Needed to scroll content to a visible area when the keyboard appears.
    ///
    private lazy var keyboardFrameObserver = KeyboardFrameObserver(onKeyboardFrameUpdate: { [weak self] frame in
        self?.handleKeyboardFrameUpdate(keyboardFrame: frame)
    })

    /// Init
    ///
    init(siteID: Int64, type: ShipType, address: ShippingLabelAddress?, completion: @escaping Completion) {
        viewModel = ShippingLabelAddressFormViewModel(siteID: siteID, type: type, address: address)
        onCompletion = completion
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
        observeViewModel()
        configureConfirmButton()
        keyboardFrameObserver.startObservingKeyboardFrame(sendInitialEvent: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.updateHeaderHeight()
    }
}

// MARK: - View Configuration
//
private extension ShippingLabelAddressFormViewController {

    func configureNavigationBar() {
        title = viewModel.type == .origin ? Localization.titleViewShipFrom : Localization.titleViewShipTo
        if viewModel.showLoadingIndicator {
            configureRightButtonItemAsLoader()
        } else {
            configureRightBarButtonItemAsDone()
        }
    }

    func configureRightBarButtonItemAsDone() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
    }

    func configureRightButtonItemAsLoader() {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .navigationBarLoadingIndicator
        indicator.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: indicator)
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

        // Configure header container view
        let headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: Int(tableView.frame.width), height: 0))
        headerContainer.addSubview(topStackView)
        headerContainer.pinSubviewToSafeArea(topStackView)
        topStackView.addArrangedSubview(topBannerView)

        tableView.tableHeaderView = headerContainer
    }

    func registerTableViewCells() {
            tableView.registerNib(for: TitleAndTextFieldTableViewCell.self)
            tableView.registerNib(for: BasicTableViewCell.self)
    }

    func observeViewModel() {
        viewModel.onChange = { [weak self] in
            guard let self = self else { return }
            self.configureNavigationBar()
            self.updateTopBannerView()
            self.tableView.reloadData()
        }
    }

    func updateTopBannerView() {
        topBannerView.isHidden = !viewModel.shouldShowTopBannerView
        tableView.updateHeaderHeight()
    }

    func configureConfirmButton() {
        confirmButton.setTitle(Localization.confirmButtonTitle, for: .normal)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        confirmButton.applySecondaryButtonStyle()
    }
}

// MARK: - Actions
//
private extension ShippingLabelAddressFormViewController {

    @objc func doneButtonTapped() {
        viewModel.validateAddress(onlyLocally: false) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success:
                self.onCompletion(self.viewModel.address)
                self.navigationController?.popViewController(animated: true)
            case .failure:
                break
            }
        }
    }

    @objc func confirmButtonTapped() {
        viewModel.validateAddress(onlyLocally: true) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success:
                self.onCompletion(self.viewModel.address)
                self.navigationController?.popViewController(animated: true)
            case .failure:
                break
            }
        }
    }
}

// MARK: - Utils
private extension ShippingLabelAddressFormViewController {
    /// Enqueues the `Apple Maps` Error Notice.
    ///
    private func displayAppleMapsErrorNotice() {
        let notice = Notice(title: Localization.appleMapsErrorNotice, feedbackType: .error, actionTitle: nil, actionHandler: nil)
        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Enqueues the `Phone Number`  Error Notice.
    ///
    private func displayPhoneNumberErrorNotice() {
        let notice = Notice(title: Localization.phoneNumberErrorNotice, feedbackType: .error, actionTitle: nil, actionHandler: nil)
        ServiceLocator.noticePresenter.enqueue(notice: notice)
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
        switch (row, cell) {
        case (.name, let cell as TitleAndTextFieldTableViewCell):
            configureName(cell: cell, row: row)
        case (.company, let cell as TitleAndTextFieldTableViewCell):
            configureCompany(cell: cell, row: row)
        case (.phone, let cell as TitleAndTextFieldTableViewCell):
            configurePhone(cell: cell, row: row)
        case (.address, let cell as TitleAndTextFieldTableViewCell):
            configureAddress(cell: cell, row: row)
        case (.address2, let cell as TitleAndTextFieldTableViewCell):
            configureAddress2(cell: cell, row: row)
        case (let .fieldError(error), let cell as BasicTableViewCell):
            configureFieldError(cell: cell, row: row, error: error)
        case (.city, let cell as TitleAndTextFieldTableViewCell):
            configureCity(cell: cell, row: row)
        case (.postcode, let cell as TitleAndTextFieldTableViewCell):
            configurePostcode(cell: cell, row: row)
        case (.state, let cell as TitleAndTextFieldTableViewCell):
            configureState(cell: cell, row: row)
        case (.country, let cell as TitleAndTextFieldTableViewCell):
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
                                                                     textFieldAlignment: .leading) { [weak self] (newText) in
            self?.viewModel.handleAddressValueChanges(row: row, newValue: newText)
        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureCompany(cell: TitleAndTextFieldTableViewCell, row: Row) {
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.companyField,
                                                                     text: viewModel.address?.company,
                                                                     placeholder: Localization.companyFieldPlaceholder,
                                                                     state: .normal,
                                                                     keyboardType: .default,
                                                                     textFieldAlignment: .leading) { [weak self] (newText) in
            self?.viewModel.handleAddressValueChanges(row: row, newValue: newText)
        }
        cell.configure(viewModel: cellViewModel)
    }

    func configurePhone(cell: TitleAndTextFieldTableViewCell, row: Row) {
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.phoneField,
                                                                     text: viewModel.address?.phone,
                                                                     placeholder: Localization.phoneFieldPlaceholder,
                                                                     state: .normal,
                                                                     keyboardType: .phonePad,
                                                                     textFieldAlignment: .leading) { [weak self] (newText) in
            self?.viewModel.handleAddressValueChanges(row: row, newValue: newText)
        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureAddress(cell: TitleAndTextFieldTableViewCell, row: Row) {
        let state: TitleAndTextFieldTableViewCell.ViewModel.State = viewModel.addressValidationError?.addressError == nil ? .normal : .error
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.addressField,
                                                                     text: viewModel.address?.address1,
                                                                     placeholder: Localization.addressFieldPlaceholder,
                                                                     state: state,
                                                                     keyboardType: .default,
                                                                     textFieldAlignment: .leading) { [weak self] (newText) in
            self?.viewModel.handleAddressValueChanges(row: row, newValue: newText)
        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureAddress2(cell: TitleAndTextFieldTableViewCell, row: Row) {
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.address2Field,
                                                                     text: viewModel.address?.address2,
                                                                     placeholder: Localization.address2FieldPlaceholder,
                                                                     state: .normal,
                                                                     keyboardType: .default,
                                                                     textFieldAlignment: .leading) { [weak self] (newText) in
            self?.viewModel.handleAddressValueChanges(row: row, newValue: newText)
        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureFieldError(cell: BasicTableViewCell, row: Row, error: ShippingLabelAddressFormViewModel.ValidationError) {
        var errorMessage = viewModel.addressValidationError?.addressError
        switch error {
        case .name:
            errorMessage = Localization.missingName
        case .address:
            errorMessage = viewModel.addressValidationError?.addressError ?? Localization.missingAddress
        case .city:
            errorMessage = Localization.missingCity
        case .postcode:
            errorMessage = Localization.missingPostcode
        case .state:
            errorMessage = Localization.missingState
        case .country:
            errorMessage = Localization.missingCountry
        }

        cell.textLabel?.text = errorMessage
        cell.textLabel?.textColor = .error
        cell.backgroundColor = .listBackground
    }

    func configureCity(cell: TitleAndTextFieldTableViewCell, row: Row) {
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.cityField,
                                                                     text: viewModel.address?.city,
                                                                     placeholder: Localization.cityFieldPlaceholder,
                                                                     state: .normal,
                                                                     keyboardType: .default,
                                                                     textFieldAlignment: .leading) { [weak self] (newText) in
            self?.viewModel.handleAddressValueChanges(row: row, newValue: newText)
        }
        cell.configure(viewModel: cellViewModel)
    }

    func configurePostcode(cell: TitleAndTextFieldTableViewCell, row: Row) {
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.postcodeField,
                                                                     text: viewModel.address?.postcode,
                                                                     placeholder: Localization.postcodeFieldPlaceholder,
                                                                     state: .normal,
                                                                     keyboardType: .phonePad,
                                                                     textFieldAlignment: .leading) { [weak self] (newText) in
            self?.viewModel.handleAddressValueChanges(row: row, newValue: newText)
        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureState(cell: TitleAndTextFieldTableViewCell, row: Row) {
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.stateField,
                                                                     text: viewModel.address?.state,
                                                                     placeholder: Localization.stateFieldPlaceholder,
                                                                     state: .normal,
                                                                     keyboardType: .default,
                                                                     textFieldAlignment: .leading) { [weak self] (newText) in
            self?.viewModel.handleAddressValueChanges(row: row, newValue: newText)
        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureCountry(cell: TitleAndTextFieldTableViewCell, row: Row) {
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.countryField,
                                                                     text: viewModel.address?.country,
                                                                     placeholder: Localization.countryFieldPlaceholder,
                                                                     state: .normal,
                                                                     keyboardType: .default,
                                                                     textFieldAlignment: .leading) { [weak self] (newText) in
            self?.viewModel.handleAddressValueChanges(row: row, newValue: newText)
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

    enum Row: Equatable {
        case name
        case company
        case phone
        case address
        case address2
        case city
        case postcode
        case state
        case country

        case fieldError(_ validationError: ShippingLabelAddressFormViewModel.ValidationError)

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .fieldError:
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
        static let missingName = NSLocalizedString("Name missing",
                                                   comment: "Error showed in Shipping Label Address Validation for the name field")
        static let missingAddress = NSLocalizedString("Address missing",
                                                      comment: "Error showed in Shipping Label Address Validation for the address field")
        static let missingCity = NSLocalizedString("City missing",
                                                   comment: "Error showed in Shipping Label Address Validation for the city field")
        static let missingPostcode = NSLocalizedString("Postcode missing",
                                                       comment: "Error showed in Shipping Label Address Validation for the postcode field")
        static let missingState = NSLocalizedString("State missing",
                                                    comment: "Error showed in Shipping Label Address Validation for the state field")
        static let missingCountry = NSLocalizedString("Country missing",
                                                      comment: "Error showed in Shipping Label Address Validation for the country field")
        static let appleMapsErrorNotice = NSLocalizedString("Error in finding the address in Apple Maps",
                                                            comment: "Error in finding the address in the Shipping Label Address Validation in Apple Maps")
        static let phoneNumberErrorNotice = NSLocalizedString("The phone number is not valid or you can't call the customer from this device.",
            comment: "Error in calling the phone number of the customer in the Shipping Label Address Validation")
    }

    enum Constants {
        static let headerContainerInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}
