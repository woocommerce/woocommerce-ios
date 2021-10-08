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
    private var topBannerView: TopBannerView {
        let topBanner = ShippingLabelAddressTopBannerFactory.addressErrorTopBannerView(
            shipType: viewModel.type,
            phoneNumber: viewModel.address?.phone
        ) { [weak self] in
            MapsHelper.openAppleMaps(address: self?.viewModel.address?.formattedPostalAddress) { [weak self] (result) in
                ServiceLocator.analytics.track(.shippingLabelEditAddressOpenMapButtonTapped)
                switch result {
                case .success:
                    break
                case .failure:
                    self?.displayAppleMapsErrorNotice()
                }
            }
        } contactCustomerPressed: { [weak self] in
            ServiceLocator.analytics.track(.shippingLabelEditAddressContactCustomerButtonTapped)
            if PhoneHelper.callPhoneNumber(phone: self?.viewModel.address?.phone) == false {
                self?.displayPhoneNumberErrorNotice()
            }
        }

        topBanner.translatesAutoresizingMaskIntoConstraints = false
        return topBanner
    }

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
    init(siteID: Int64,
         type: ShipType,
         address: ShippingLabelAddress?,
         phoneNumberRequired: Bool = false,
         validationError: ShippingLabelAddressValidationError?,
         countries: [Country],
         completion: @escaping Completion ) {
        viewModel = ShippingLabelAddressFormViewModel(siteID: siteID,
                                                      type: type,
                                                      address: address,
                                                      phoneNumberRequired: phoneNumberRequired,
                                                      validationError: validationError,
                                                      countries: countries)
        onCompletion = completion
        super.init(nibName: nil, bundle: nil)
        switch type {
        case .origin:
            ServiceLocator.analytics.track(.shippingLabelPurchaseFlow, withProperties: ["state": "origin_address_started"])
        case .destination:
            ServiceLocator.analytics.track(.shippingLabelPurchaseFlow, withProperties: ["state": "destination_address_started"])
        }
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
        updateTopBannerView()
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
        tableView.delegate = self
    }

    func registerTableViewCells() {
        tableView.registerNib(for: TitleAndTextFieldTableViewCell.self)
        tableView.registerNib(for: BasicTableViewCell.self)
    }

    func observeViewModel() {
        viewModel.onChange = { [weak self] focusedIndex in
            guard let self = self else { return }
            self.configureNavigationBar()
            self.updateTopBannerView()
            self.tableView.reloadData()
            if let index = focusedIndex,
               let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? TitleAndTextFieldTableViewCell {
                cell.textFieldBecomeFirstResponder()
            }
        }
    }

    func updateTopBannerView() {
        if !viewModel.shouldShowTopBannerView {
            hideTopBannerView()
        }
        else {
            displayTopBannerView()
        }
    }

    func displayTopBannerView() {
        // Configure header container view
        let headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: Int(tableView.frame.width), height: 0))
        headerContainer.addSubview(topStackView)
        headerContainer.pinSubviewToAllEdges(topStackView)

        topStackView.removeAllArrangedSubviews()
        topStackView.addArrangedSubview(topBannerView)

        tableView.tableHeaderView = headerContainer
        tableView.updateHeaderHeight()
    }

    func hideTopBannerView() {
        guard tableView.tableHeaderView != nil else {
            return
        }

        topBannerView.removeFromSuperview()
        tableView.tableHeaderView = nil
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
        ServiceLocator.analytics.track(.shippingLabelEditAddressDoneButtonTapped)
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
        ServiceLocator.analytics.track(.shippingLabelEditAddressUseAddressAsIsButtonTapped)
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

// MARK: - UITableViewDelegate Conformance
//
extension ShippingLabelAddressFormViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = viewModel.sections[indexPath.section].rows[indexPath.row]
        switch row {
        case .state:
            let states = viewModel.statesOfSelectedCountry
            guard states.isNotEmpty else {
                return
            }
            let selectedState = states.first { $0.code == viewModel.address?.state }
            let command = ShippingLabelStateOfACountryListSelectorCommand(states: states, selected: selectedState)
            let listSelector = ListSelectorViewController(command: command) { [weak self] state in
                self?.viewModel.handleAddressValueChanges(row: .state, newValue: state?.code)
                self?.tableView.reloadData()
            }
            show(listSelector, sender: self)

        case .country:
            guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.shippingLabelsInternational) else {
                let notice = Notice(title: Localization.countryNotEditable, feedbackType: .warning)
                ServiceLocator.noticePresenter.enqueue(notice: notice)
                return
            }

            let countries = viewModel.countries
            let selectedCountry = countries.first { $0.code == viewModel.address?.country }
            let command = ShippingLabelCountryListSelectorCommand(countries: countries, selected: selectedCountry)
            let listSelector = ListSelectorViewController(command: command) { [weak self] country in
                self?.viewModel.handleAddressValueChanges(row: .country, newValue: country?.code)
                self?.tableView.reloadData()
            }
            show(listSelector, sender: self)

        default:
            break
        }
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
        let placeholder = viewModel.nameRequired ? Localization.requiredNameFieldPlaceholder : Localization.optionalNameFieldPlaceholder
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.nameField,
                                                                     text: viewModel.address?.name,
                                                                     placeholder: placeholder,
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
        let placeholder = viewModel.phoneNumberRequired ? Localization.phoneFieldPlaceholderRequired : Localization.phoneFieldPlaceholder
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.phoneField,
                                                                     text: viewModel.address?.phone,
                                                                     placeholder: placeholder,
                                                                     state: .normal,
                                                                     keyboardType: .phonePad,
                                                                     textFieldAlignment: .leading) { [weak self] (newText) in
            let phone = newText?.filter { "0"..."9" ~= $0 }
            self?.viewModel.handleAddressValueChanges(row: row, newValue: phone)
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
        case .missingPhoneNumber:
            errorMessage = Localization.missingPhoneNumber
        case .invalidPhoneNumber:
            errorMessage = Localization.invalidPhoneNumber
        }

        cell.textLabel?.text = errorMessage
        cell.textLabel?.textColor = .error
        cell.textLabel?.numberOfLines = 0
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
        let placeholder = viewModel.stateOfCountryRequired ? Localization.stateFieldPlaceholder : Localization.stateFieldPlaceholderOptional
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.stateField,
                                                                     text: viewModel.extendedStateName,
                                                                     placeholder: placeholder,
                                                                     state: .normal,
                                                                     keyboardType: .default,
                                                                     textFieldAlignment: .leading) { _ in }
        cell.configure(viewModel: cellViewModel)
        cell.enableTextField(viewModel.statesOfSelectedCountry.isEmpty)
    }

    func configureCountry(cell: TitleAndTextFieldTableViewCell, row: Row) {
        let cellViewModel = TitleAndTextFieldTableViewCell.ViewModel(title: Localization.countryField,
                                                                     text: viewModel.extendedCountryName,
                                                                     placeholder: Localization.countryFieldPlaceholder,
                                                                     state: .normal,
                                                                     keyboardType: .default,
                                                                     textFieldAlignment: .leading) { _ in }
        cell.configure(viewModel: cellViewModel)
        cell.enableTextField(false)
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
        static let requiredNameFieldPlaceholder = NSLocalizedString("Required",
                                                                    comment: "Name text field placeholder in Shipping Label "
                                                                    + "Address Validation when it's required")
        static let optionalNameFieldPlaceholder = NSLocalizedString("Optional",
                                                                    comment: "Name text field placeholder in Shipping Label "
                                                                    + "Address Validation when it's optional")
        static let companyField = NSLocalizedString("Company", comment: "Text field company in Shipping Label Address Validation")
        static let companyFieldPlaceholder = NSLocalizedString("Optional", comment: "Text field placeholder in Shipping Label Address Validation")
        static let phoneField = NSLocalizedString("Phone", comment: "Text field phone in Shipping Label Address Validation")
        static let phoneFieldPlaceholder = NSLocalizedString("Optional", comment: "Text field placeholder in Shipping Label Address Validation")
        static let phoneFieldPlaceholderRequired = NSLocalizedString("Required",
                                                                     comment: "Text field placeholder in Shipping Label Address Validation " +
                                                                     "when phone number is required")
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
        static let stateFieldPlaceholderOptional = NSLocalizedString(
            "Optional",
            comment: "Text field placeholder in Shipping Label Address Validation when specified country has no state"
        )
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
        static let missingPhoneNumber = NSLocalizedString("A phone number is required because this shipment requires a customs form",
                                                          comment: "Error shown in Shipping Label Origin Address validation for " +
                                                          "phone number field for international shipment")
        static let invalidPhoneNumber = NSLocalizedString("Custom forms require a 10-digit phone number",
                                                          comment: "Error shown in Shipping Label Origin Address validation for " +
                                                            "phone number when the it doesn't have expected length for international shipment.")
        static let appleMapsErrorNotice = NSLocalizedString("Error in finding the address in Apple Maps",
                                                            comment: "Error in finding the address in the Shipping Label Address Validation in Apple Maps")
        static let phoneNumberErrorNotice = NSLocalizedString("The phone number is not valid or you can't call the customer from this device.",
            comment: "Error in calling the phone number of the customer in the Shipping Label Address Validation")
        static let countryNotEditable = NSLocalizedString("Currently we support just the United States from mobile.",
                                                          comment: "Error when the user tap on Country field in Shipping Label Address Validation")
    }
}
