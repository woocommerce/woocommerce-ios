import UIKit
import Yosemite
import SwiftUI
import WordPressUI

final class ShippingLabelFormViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let viewModel: ShippingLabelFormViewModel

    /// Can be set to true to mark the order as complete when the label is purchased
    ///
    private var shouldMarkOrderComplete = false

    /// Assign this closure to be notified after a shipping label is successfully purchased
    ///
    var onLabelPurchase: ((_ isOrderComplete: Bool) -> Void)?

    /// Assign this closure to be notified after a shipping label is saved for later
    ///
    var onLabelSave: (() -> Void)?

    /// Init
    ///
    init(order: Order) {
        viewModel = ShippingLabelFormViewModel(order: order,
                                               originAddress: nil,
                                               destinationAddress: order.shippingAddress)
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
        registerTableViewHeaderFooters()
        observeViewModel()
    }
}

// MARK: - View Configuration
//
private extension ShippingLabelFormViewController {

    func configureNavigationBar() {
        title = Localization.titleView
    }

    func configureMainView() {
        view.backgroundColor = .listForeground
    }

    func configureTableView() {
        view.backgroundColor = .listBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground
        tableView.separatorStyle = .none

        registerTableViewCells()
        registerTableViewHeaderFooters()

        tableView.dataSource = self
        tableView.delegate = self
    }

    func registerTableViewCells() {
        for row in RowType.allCases {
            tableView.registerNib(for: row.type)
        }
    }

    /// Registers all of the available TableViewHeaderFooters
    ///
    func registerTableViewHeaderFooters() {
        let headersAndFooters = [
            TwoColumnSectionHeaderView.self
        ]

        for kind in headersAndFooters {
            tableView.register(kind.loadNib(), forHeaderFooterViewReuseIdentifier: kind.reuseIdentifier)
        }
    }

    func observeViewModel() {
        viewModel.onChange = { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
        }
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ShippingLabelFormViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.state.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.state.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.state.sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.type.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if viewModel.state.sections[section].title == nil {
            return CGFloat.leastNormalMagnitude
        }

        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let leftText = viewModel.state.sections[section].title else {
            return nil
        }

        let headerID = TwoColumnSectionHeaderView.reuseIdentifier
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerID) as? TwoColumnSectionHeaderView else {
            fatalError()
        }

        headerView.leftText = leftText
        headerView.rightText = nil

        return headerView
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension ShippingLabelFormViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = viewModel.state.sections[indexPath.section].rows[indexPath.row]
        switch row {
        case Row(type: .shipFrom, dataState: .validated, displayMode: .editable):
            displayEditAddressFormVC(address: viewModel.originAddress, validationError: nil, type: .origin)
        case Row(type: .shipTo, dataState: .validated, displayMode: .editable):
            displayEditAddressFormVC(address: viewModel.destinationAddress, validationError: nil, type: .destination)
        case Row(type: .packageDetails, dataState: .validated, displayMode: .editable):
            displayPackageDetailsVC(selectedPackageID: viewModel.selectedPackageID,
                                    totalPackageWeight: viewModel.totalPackageWeight)
        case Row(type: .shippingCarrierAndRates, dataState: .validated, displayMode: .editable):
            displayCarriersAndRatesVC(selectedRate: viewModel.selectedRate,
                                      selectedSignatureRate: viewModel.selectedSignatureRate,
                                      selectedAdultSignatureRate: viewModel.selectedAdultSignatureRate)
        case Row(type: .paymentMethod, dataState: .validated, displayMode: .editable):
            displayPaymentMethodVC()
        default:
            break
        }
    }
}

// MARK: - Cell configuration
//
private extension ShippingLabelFormViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as ShippingLabelFormStepTableViewCell where row.type == .shipFrom:
            configureShipFrom(cell: cell, row: row)
        case let cell as ShippingLabelFormStepTableViewCell where row.type == .shipTo:
            configureShipTo(cell: cell, row: row)
        case let cell as ShippingLabelFormStepTableViewCell where row.type == .packageDetails:
            configurePackageDetails(cell: cell, row: row)
        case let cell as ShippingLabelFormStepTableViewCell where row.type == .shippingCarrierAndRates:
            configureShippingCarrierAndRates(cell: cell, row: row)
        case let cell as ShippingLabelFormStepTableViewCell where row.type == .paymentMethod:
            configurePaymentMethod(cell: cell, row: row)
        case let cell as ShippingLabelSummaryTableViewCell where row.type == .orderSummary:
            configureOrderSummary(cell: cell, row: row)
        default:
            fatalError("Cannot instantiate \(cell) with row \(row.type)")
            break
        }
    }

    func configureShipFrom(cell: ShippingLabelFormStepTableViewCell, row: Row) {
        cell.configure(state: row.cellState,
                       icon: .shippingImage,
                       title: Localization.shipFromCellTitle,
                       body: viewModel.originAddress?.fullNameWithCompanyAndAddress,
                       buttonTitle: Localization.continueButtonInCells) { [weak self] in
            guard let self = self else { return }
            self.viewModel.validateAddress(type: .origin) { [weak self] (validationState, response) in
                guard let self = self else { return }
                let shippingLabelAddress = self.viewModel.originAddress
                switch validationState {
                case .validated:
                    self.viewModel.handleOriginAddressValueChanges(address: shippingLabelAddress,
                                                                   validated: true)
                case .suggestedAddress:
                    self.displaySuggestedAddressVC(address: shippingLabelAddress, suggestedAddress: response?.address, type: .origin)
                default:
                    self.displayEditAddressFormVC(address: shippingLabelAddress, validationError: nil, type: .origin)
                }
            }
        }

        cell.showActivityIndicator(viewModel.state.isValidatingOriginAddress)
        cell.enableButton(!viewModel.state.isValidatingOriginAddress)
    }

    func configureShipTo(cell: ShippingLabelFormStepTableViewCell, row: Row) {
        cell.configure(state: row.cellState,
                       icon: .houseOutlinedImage,
                       title: Localization.shipToCellTitle,
                       body: viewModel.destinationAddress?.fullNameWithCompanyAndAddress,
                       buttonTitle: Localization.continueButtonInCells) { [weak self] in
            guard let self = self else { return }

            self.viewModel.validateAddress(type: .destination) { [weak self] (validationState, response) in
                guard let self = self else { return }
                let shippingLabelAddress = self.viewModel.destinationAddress
                switch validationState {
                case .validated:
                    self.viewModel.handleDestinationAddressValueChanges(address: shippingLabelAddress,
                                                                   validated: true)
                case .suggestedAddress:
                    self.displaySuggestedAddressVC(address: shippingLabelAddress, suggestedAddress: response?.address, type: .destination)
                case .validationError(let validationError):
                    self.displayEditAddressFormVC(address: shippingLabelAddress, validationError: validationError, type: .destination)
                case .genericError(let error):
                    let validationError = ShippingLabelAddressValidationError(addressError: nil, generalError: error.localizedDescription)
                    self.displayEditAddressFormVC(address: shippingLabelAddress, validationError: validationError, type: .destination)
                }
            }
        }
        cell.showActivityIndicator(viewModel.state.isValidatingDestinationAddress)
        cell.enableButton(!viewModel.state.isValidatingDestinationAddress)
    }

    func configurePackageDetails(cell: ShippingLabelFormStepTableViewCell, row: Row) {
        cell.configure(state: row.cellState,
                       icon: .productPlaceholderImage,
                       title: Localization.packageDetailsCellTitle,
                       body: viewModel.getPackageDetailsBody(),
                       buttonTitle: Localization.continueButtonInCells) { [weak self] in
            self?.displayPackageDetailsVC(selectedPackageID: self?.viewModel.selectedPackageID,
                                          totalPackageWeight: self?.viewModel.totalPackageWeight)
        }
    }

    func configureShippingCarrierAndRates(cell: ShippingLabelFormStepTableViewCell, row: Row) {
        cell.configure(state: row.cellState,
                       icon: .priceImage,
                       title: Localization.shippingCarrierAndRatesCellTitle,
                       body: viewModel.getCarrierAndRatesBody(),
                       buttonTitle: Localization.continueButtonInCells) { [weak self] in
            self?.displayCarriersAndRatesVC(selectedRate: self?.viewModel.selectedRate,
                                            selectedSignatureRate: self?.viewModel.selectedSignatureRate,
                                            selectedAdultSignatureRate: self?.viewModel.selectedAdultSignatureRate)
        }
    }

    func configurePaymentMethod(cell: ShippingLabelFormStepTableViewCell, row: Row) {
        cell.configure(state: row.cellState,
                       icon: .creditCardImage,
                       title: Localization.paymentMethodCellTitle,
                       body: viewModel.getPaymentMethodBody(),
                       buttonTitle: Localization.continueButtonInCells) {
            // To be implemented as part of the "Add new payment method" flow
        }
    }

    func configureOrderSummary(cell: ShippingLabelSummaryTableViewCell, row: Row) {
        cell.configure(state: row.cellState) {
            let discountInfoVC = ShippingLabelDiscountInfoViewController()
            let bottomSheet = BottomSheetViewController(childViewController: discountInfoVC)
            bottomSheet.show(from: self, sourceView: cell)
        } onSwitchChange: { (switchIsOn) in
            self.shouldMarkOrderComplete = switchIsOn
        } onButtonTouchUp: {
            self.displayPurchaseProgressView()
            self.viewModel.purchaseLabel { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.onLabelPurchase?(self.shouldMarkOrderComplete)
                    self.dismiss(animated: true)
                    self.displayPrintShippingLabelVC()
                case .failure:
                    // TODO: Implement and display error screen for purchase failures
                    self.dismiss(animated: true)
                    break
                }
            }
        }
        cell.isOn = false
        cell.setSubtotal(viewModel.getSubtotal())
        cell.setDiscount(viewModel.getDiscount())
        cell.setOrderTotal(viewModel.getOrderTotal())
    }
}

// MARK: - Actions
//
private extension ShippingLabelFormViewController {
    func displayEditAddressFormVC(address: ShippingLabelAddress?, validationError: ShippingLabelAddressValidationError?, type: ShipType) {
        guard viewModel.countries.isNotEmpty else {
            let notice = Notice(title: Localization.noticeUnableToFetchCountries, feedbackType: .error, actionTitle: Localization.noticeRetryAction) {
                [weak self] in
                self?.viewModel.fetchCountries()
            }
            ServiceLocator.noticePresenter.enqueue(notice: notice)
            return
        }
        let shippingAddressVC = ShippingLabelAddressFormViewController(
            siteID: viewModel.siteID,
            type: type,
            address: address,
            validationError: validationError,
            countries: viewModel.countries,
            completion: { [weak self] (newShippingLabelAddress) in
                guard let self = self else { return }
                switch type {
                case .origin:
                    self.viewModel.handleOriginAddressValueChanges(address: newShippingLabelAddress,
                                                                   validated: true)
                case .destination:
                    self.viewModel.handleDestinationAddressValueChanges(address: newShippingLabelAddress,
                                                                        validated: true)
                }
            })
        navigationController?.pushViewController(shippingAddressVC, animated: true)
    }

    func displaySuggestedAddressVC(address: ShippingLabelAddress?, suggestedAddress: ShippingLabelAddress?, type: ShipType) {
        guard viewModel.countries.isNotEmpty else {
            let notice = Notice(title: Localization.noticeUnableToFetchCountries, feedbackType: .error, actionTitle: Localization.noticeRetryAction) {
                [weak self] in
                self?.viewModel.fetchCountries()
            }
            ServiceLocator.noticePresenter.enqueue(notice: notice)
            return
        }
        let vc = ShippingLabelSuggestedAddressViewController(siteID: viewModel.siteID,
                                                             type: type,
                                                             address: address,
                                                             suggestedAddress: suggestedAddress,
                                                             countries: viewModel.countries) { [weak self] (newShippingLabelAddress) in
            switch type {
            case .origin:
                self?.viewModel.handleOriginAddressValueChanges(address: newShippingLabelAddress,
                                                                validated: true)
            case .destination:
                self?.viewModel.handleDestinationAddressValueChanges(address: newShippingLabelAddress,
                                                                     validated: true)
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    func displayPackageDetailsVC(selectedPackageID: String?, totalPackageWeight: String?) {
        let vm = ShippingLabelPackageDetailsViewModel(order: viewModel.order,
                                                      packagesResponse: viewModel.packagesResponse,
                                                      selectedPackageID: selectedPackageID,
                                                      totalWeight: totalPackageWeight)
        let packageDetails = ShippingLabelPackageDetails(viewModel: vm) { [weak self] (selectedPackageID, totalPackageWeight) in
            self?.viewModel.handlePackageDetailsValueChanges(selectedPackageID: selectedPackageID, totalPackageWeight: totalPackageWeight)
        }

        let hostingVC = UIHostingController(rootView: packageDetails)
        hostingVC.title = Localization.navigationBarTitlePackageDetails

        navigationController?.show(hostingVC, sender: nil)
    }

    func displayCarriersAndRatesVC(selectedRate: ShippingLabelCarrierRate?,
                                   selectedSignatureRate: ShippingLabelCarrierRate?,
                                   selectedAdultSignatureRate: ShippingLabelCarrierRate?) {
        guard let originAddress = viewModel.originAddress,
              let destinationAddress = viewModel.destinationAddress,
              let selectedPackage = viewModel.selectedPackage else {
            return
        }

        let vm = ShippingLabelCarriersViewModel(order: viewModel.order,
                                                originAddress: originAddress,
                                                destinationAddress: destinationAddress,
                                                packages: [selectedPackage],
                                                selectedRate: selectedRate,
                                                selectedSignatureRate: selectedSignatureRate,
                                                selectedAdultSignatureRate: selectedAdultSignatureRate)

        let carriersView = ShippingLabelCarriers(viewModel: vm) { [weak self] (selectedRate,
                                                                               selectedSignatureRate,
                                                                               selectedAdultSignatureRate) in
            self?.viewModel.handleCarrierAndRatesValueChanges(selectedRate: selectedRate,
                                                              selectedSignatureRate: selectedSignatureRate,
                                                              selectedAdultSignatureRate: selectedAdultSignatureRate,
                                                              editable: true)
        }
        let hostingVC = UIHostingController(rootView: carriersView)
        navigationController?.show(hostingVC, sender: nil)
    }

    func displayPaymentMethodVC() {
        guard let accountSettings = viewModel.shippingLabelAccountSettings else {
            return
        }

        let vm = ShippingLabelPaymentMethodsViewModel(accountSettings: accountSettings)
        let paymentMethod = ShippingLabelPaymentMethods(viewModel: vm) { [weak self] newSettings in
            guard let self = self else { return }
            self.viewModel.handlePaymentMethodValueChanges(settings: newSettings, editable: true)
        }

        let hostingVC = UIHostingController(rootView: paymentMethod)
        navigationController?.show(hostingVC, sender: nil)
    }

    func displayPurchaseProgressView() {
        let viewProperties = InProgressViewProperties(title: Localization.purchaseProgressTitle, message: Localization.purchaseProgressMessage)
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)
        inProgressViewController.modalPresentationStyle = .overFullScreen

        present(inProgressViewController, animated: true)
    }

    /// Removes the Shipping Label Form from the navigation stack and displays the Print Shipping Label screen.
    /// This prevents navigating back to the purchase form after successfully purchasing the label.
    ///
    func displayPrintShippingLabelVC() {
        guard let purchasedShippingLabel = viewModel.purchasedShippingLabel,
              let navigationController = navigationController else {
            return
        }

        if let indexOfSelf = navigationController.viewControllers.firstIndex(of: self) {
            let viewControllersExcludingSelf = Array(navigationController.viewControllers[0..<indexOfSelf])
            navigationController.setViewControllers(viewControllersExcludingSelf, animated: false)
        }
        let printCoordinator = PrintShippingLabelCoordinator(shippingLabel: purchasedShippingLabel,
                                                             printType: .print,
                                                             sourceViewController: navigationController,
                                                             onCompletion: onLabelSave)
        printCoordinator.showPrintUI()
    }
}

extension ShippingLabelFormViewController {

    struct Section: Equatable {
        let title: String?
        let rows: [Row]
    }

    struct Row: Equatable {
        let type: RowType
        let dataState: DataState
        let displayMode: DisplayMode

        fileprivate var cellState: ShippingLabelFormStepTableViewCell.State {
            if dataState == .validated && displayMode == .editable {
                return .enabled
            }
            else if dataState == .pending && displayMode == .editable {
                return .continue
            }
            return .disabled
        }
    }

    /// Each row has a data state
    enum DataState {
        /// the data are validated
        case validated

        /// the data still need to be validated
        case pending
    }

    /// Each row has a UI state
    enum DisplayMode {
        /// the row is not greyed out and is available for edit (a disclosure indicator is shown in the accessory view) and
        /// "Continue" CTA is shown to edit the row details
        case editable

        /// the row is greyed out
        case disabled
    }

    enum RowType: CaseIterable {
        case shipFrom
        case shipTo
        case packageDetails
        case shippingCarrierAndRates
        case paymentMethod
        case orderSummary

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .shipFrom, .shipTo, .packageDetails, .shippingCarrierAndRates, .paymentMethod:
                return ShippingLabelFormStepTableViewCell.self
            case .orderSummary:
                return ShippingLabelSummaryTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

private extension ShippingLabelFormViewController {
    enum Localization {
        static let titleView = NSLocalizedString("Create Shipping Label", comment: "Create Shipping Label form navigation title")
        static let shipFromCellTitle = NSLocalizedString("Ship from", comment: "Title of the cell Ship from inside Create Shipping Label form")
        static let shipToCellTitle = NSLocalizedString("Ship to", comment: "Title of the cell Ship From inside Create Shipping Label form")
        static let packageDetailsCellTitle = NSLocalizedString("Package Details",
                                                               comment: "Title of the cell Package Details inside Create Shipping Label form")
        static let shippingCarrierAndRatesCellTitle = NSLocalizedString("Shipping Carrier and Rates",
                                                                        comment: "Title of the cell Shipping Carrier inside Create Shipping Label form")
        static let paymentMethodCellTitle = NSLocalizedString("Payment Method",
                                                              comment: "Title of the cell Payment Method inside Create Shipping Label form")
        static let continueButtonInCells = NSLocalizedString("Continue",
                                                             comment: "Continue button inside every cell inside Create Shipping Label form")
        static let navigationBarTitlePackageDetails =
            NSLocalizedString("Package Details",
                              comment: "Navigation bar title of shipping label package details screen")
        // Purchase progress view
        static let purchaseProgressTitle = NSLocalizedString("Purchasing Label", comment: "Title of the in-progress UI while purchasing a shipping label")
        static let purchaseProgressMessage = NSLocalizedString("Please wait", comment: "Message of the in-progress UI while purchasing a shipping label")
        static let noticeUnableToFetchCountries = NSLocalizedString("Unable to fetch countries.",
                                                                    comment: "Unable to fetch countries action failed in Shipping Label Form")
        static let noticeRetryAction = NSLocalizedString("Retry", comment: "Retry Action")
    }
}
