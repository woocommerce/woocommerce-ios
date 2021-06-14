import UIKit
import Yosemite

/// Provides view data for Create Shipping Label, and handles init/UI/navigation actions needed.
///
final class ShippingLabelFormViewModel {

    /// Defines the necessary state to produce the ViewModel's outputs.
    ///
    struct State {

        var sections: [Section] = []

        /// Indicates if the view model is validating an address
        ///
        var isValidatingOriginAddress: Bool = false
        var isValidatingDestinationAddress: Bool = false
    }

    typealias Section = ShippingLabelFormViewController.Section
    typealias Row = ShippingLabelFormViewController.Row

    let siteID: Int64
    private(set) var order: Order

    /// Address
    ///
    private(set) var originAddress: ShippingLabelAddress?
    private(set) var destinationAddress: ShippingLabelAddress?

    /// Packages
    ///
    private(set) var packagesResponse: ShippingLabelPackagesResponse?
    private(set) var selectedPackageID: String?

    /// Carrier and Rates
    ///
    private(set) var selectedRate: ShippingLabelCarrierRate?
    private(set) var selectedSignatureRate: ShippingLabelCarrierRate?
    private(set) var selectedAdultSignatureRate: ShippingLabelCarrierRate?
    var selectedPackage: ShippingLabelPackageSelected? {
        guard let packagesResponse = packagesResponse else {
            return nil
        }

        if let customPackage = packagesResponse.customPackages.first(where: { $0.title == selectedPackageID }) {
            return ShippingLabelPackageSelected(boxID: customPackage.title,
                                                length: customPackage.getLength(),
                                                width: customPackage.getWidth(),
                                                height: customPackage.getHeight(),
                                                weight: customPackage.getWidth(),
                                                isLetter: customPackage.isLetter)
        }

        for option in packagesResponse.predefinedOptions {
            if let predefinedPackage = option.predefinedPackages.first(where: { $0.id == selectedPackageID }) {
                    return ShippingLabelPackageSelected(boxID: predefinedPackage.id,
                                                        length: predefinedPackage.getLength(),
                                                        width: predefinedPackage.getWidth(),
                                                        height: predefinedPackage.getHeight(),
                                                        weight: predefinedPackage.getWidth(),
                                                        isLetter: predefinedPackage.isLetter)
            }
        }

        return nil
    }
    private(set) var totalPackageWeight: String?

    /// Payment Methods
    ///
    var shippingLabelAccountSettings: ShippingLabelAccountSettings?


    private let stores: StoresManager

    /// Closure to notify the `ViewController` when the view model properties change.
    ///
    var onChange: (() -> (Void))?

    /// Current `ViewModel` state.
    ///
    private(set) var state: State = State() {
        didSet {
            onChange?()
        }
    }

    init(order: Order,
         originAddress: Address?,
         destinationAddress: Address?,
         stores: StoresManager = ServiceLocator.stores) {

        self.siteID = order.siteID
        self.order = order

        let accountSettings = ShippingLabelFormViewModel.getStoredAccountSettings()
        let company = ServiceLocator.stores.sessionManager.defaultSite?.name
        let defaultAccount = ServiceLocator.stores.sessionManager.defaultAccount

        self.originAddress = ShippingLabelFormViewModel.fromAddressToShippingLabelAddress(address: originAddress) ??
            ShippingLabelFormViewModel.getDefaultOriginAddress(accountSettings: accountSettings,
                                                               company: company,
                                                               siteAddress: SiteAddress(),
                                                               account: defaultAccount)
        self.destinationAddress = ShippingLabelFormViewModel.fromAddressToShippingLabelAddress(address: destinationAddress)

        state.sections = ShippingLabelFormViewModel.generateInitialSections()
        self.stores = stores

        syncShippingLabelAccountSettings()
        syncPackageDetails()
    }

    func handleOriginAddressValueChanges(address: ShippingLabelAddress?, validated: Bool) {
        originAddress = address
        let dateState: ShippingLabelFormViewController.DataState = validated ? .validated : .pending
        updateRowState(type: .shipFrom, dataState: dateState, displayMode: .editable)
    }

    func handleDestinationAddressValueChanges(address: ShippingLabelAddress?, validated: Bool) {
        destinationAddress = address
        let dateState: ShippingLabelFormViewController.DataState = validated ? .validated : .pending
        updateRowState(type: .shipTo, dataState: dateState, displayMode: .editable)
    }

    func handlePackageDetailsValueChanges(selectedPackageID: String?, totalPackageWeight: String?) {
        self.selectedPackageID = selectedPackageID
        self.totalPackageWeight = totalPackageWeight

        guard !selectedPackageID.isNilOrEmpty && !totalPackageWeight.isNilOrEmpty else {
            updateRowState(type: .packageDetails, dataState: .pending, displayMode: .editable)
            return
        }
        updateRowState(type: .packageDetails, dataState: .validated, displayMode: .editable)
    }

    func handleCarrierAndRatesValueChanges(selectedRate: ShippingLabelCarrierRate?,
                                           selectedSignatureRate: ShippingLabelCarrierRate?,
                                           selectedAdultSignatureRate: ShippingLabelCarrierRate?) {
        self.selectedRate = selectedRate
        self.selectedSignatureRate = selectedSignatureRate
        self.selectedAdultSignatureRate = selectedAdultSignatureRate

        guard selectedRate != nil else {
            updateRowState(type: .shippingCarrierAndRates, dataState: .pending, displayMode: .editable)
            return
        }
        updateRowState(type: .shippingCarrierAndRates, dataState: .validated, displayMode: .editable)
    }

    func handlePaymentMethodValueChanges(settings: ShippingLabelAccountSettings, editable: Bool) {
        shippingLabelAccountSettings = settings
        let displayMode: ShippingLabelFormViewController.DisplayMode = editable ? .editable : .disabled

        // Only update the data state if there is a selected payment method
        guard settings.selectedPaymentMethodID != 0 else {
            updateRowState(type: .paymentMethod, dataState: .pending, displayMode: displayMode)
            return
        }
        updateRowState(type: .paymentMethod, dataState: .validated, displayMode: displayMode)
    }

    private static func generateInitialSections() -> [Section] {
        let shipFrom = Row(type: .shipFrom, dataState: .pending, displayMode: .editable)
        let shipTo = Row(type: .shipTo, dataState: .pending, displayMode: .disabled)
        let packageDetails = Row(type: .packageDetails, dataState: .pending, displayMode: .disabled)
        let shippingCarrierAndRates = Row(type: .shippingCarrierAndRates, dataState: .pending, displayMode: .disabled)
        let paymentMethod = Row(type: .paymentMethod, dataState: .pending, displayMode: .disabled)
        let rows: [Row] = [shipFrom, shipTo, packageDetails, shippingCarrierAndRates, paymentMethod]
        return [Section(title: nil, rows: rows)]
    }

    /// Returns the body of the Package Details cell
    ///
    func getPackageDetailsBody() -> String {
        guard let packagesResponse = packagesResponse,
              let selectedPackageID = selectedPackageID,
              let totalPackageWeight = totalPackageWeight else {
            return Localization.packageDetailsPlaceholder
        }

        let packageTitle = searchCustomPackage(id: selectedPackageID)?.title ?? searchPredefinedPackage(id: selectedPackageID)?.title ?? ""

        let formatter = WeightFormatter(weightUnit: packagesResponse.storeOptions.weightUnit)
        let packageWeight = formatter.formatWeight(weight: totalPackageWeight)

        return packageTitle + "\n" + String.localizedStringWithFormat(Localization.totalPackageWeight, packageWeight)
    }

    /// Returns the body of the selected Carrier and Rates.
    ///
    func getCarrierAndRatesBody() -> String {
        guard let selectedRate = selectedRate else {
            return Localization.carrierAndRatesPlaceholder
        }

        var rate: Double = selectedRate.retailRate
        if let selectedSignatureRate = selectedSignatureRate {
            rate = selectedSignatureRate.retailRate
        }
        else if let selectedAdultSignatureRate = selectedAdultSignatureRate {
            rate = selectedAdultSignatureRate.retailRate
        }

        let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
        let price = currencyFormatter.formatAmount(Decimal(rate)) ?? ""

        let formatString = selectedRate.deliveryDays == 1 ? Localization.businessDaySingular : Localization.businessDaysPlural
        let shippingDays = String(format: formatString, selectedRate.deliveryDays)

        return selectedRate.title + "\n" + price + " - " + shippingDays
    }

    /// Returns the body of the Payment Methods cell.
    /// Displays the payment method details if one is selected. Otherwise, displays a prompt to add a credit card.
    ///
    func getPaymentMethodBody() -> String {
        let selectedPaymentMethodID = shippingLabelAccountSettings?.selectedPaymentMethodID
        let availablePaymentMethods = shippingLabelAccountSettings?.paymentMethods
        guard let selectedPaymentMethod = availablePaymentMethods?.first(where: { $0.paymentMethodID == selectedPaymentMethodID }) else {
            return Localization.paymentMethodPlaceholder
        }

        return String.localizedStringWithFormat(Localization.paymentMethodLabel, selectedPaymentMethod.cardDigits)
    }
}

// MARK: - State Machine
private extension ShippingLabelFormViewModel {

    /// We have a state machine that keeps track of a list of rows with corresponding data state and UI state.
    /// On each state change (any data change from any rows or API validation response), the state machine:
    /// First updates the date state of affected rows
    /// Then recalculates the UI state of all rows
    /// A row's UI state is `editable` if:
    /// - All previous rows (lower index) have data state as validated
    /// - For the first row, it is always editable
    ///
    func updateRowState(type: ShippingLabelFormViewController.RowType,
                        dataState: ShippingLabelFormViewController.DataState,
                        displayMode: ShippingLabelFormViewController.DisplayMode) {
        guard var rows = state.sections.first?.rows else {
            return
        }

        if let rowIndex = rows.firstIndex(where: { $0.type == type }) {
            rows[rowIndex] = Row(type: type, dataState: dataState, displayMode: displayMode)

            for index in 0 ..< rows.count {
                if rows[safe: index - 1]?.dataState == .validated {
                    let currentRow = rows[index]
                    rows[index] = Row(type: currentRow.type, dataState: currentRow.dataState, displayMode: .editable)
                }
            }
        }

        var summarySection: Section?
        if rows.allSatisfy({ (row) -> Bool in
            row.dataState == .validated && row.displayMode == .editable
        }) {
            summarySection = Section(title: Localization.orderSummaryHeader.uppercased(),
                                     rows: [Row(type: .orderSummary, dataState: .validated, displayMode: .editable)])
        }

        state.sections = [Section(title: nil, rows: rows), summarySection].compactMap { $0 }
    }
}

// MARK: - Utils
private extension ShippingLabelFormViewModel {
    // We generate the default origin address using the information
    // of the logged Account and of the website.
    static func getDefaultOriginAddress(accountSettings: AccountSettings?,
                                        company: String?,
                                        siteAddress: SiteAddress,
                                        account: Account?) -> ShippingLabelAddress? {
        let address = Address(firstName: accountSettings?.firstName ?? "",
                              lastName: accountSettings?.lastName ?? "",
                              company: company ?? "",
                              address1: siteAddress.address,
                              address2: siteAddress.address2,
                              city: siteAddress.city,
                              state: siteAddress.state,
                              postcode: siteAddress.postalCode,
                              country: siteAddress.countryCode,
                              phone: "",
                              email: account?.email)
        return fromAddressToShippingLabelAddress(address: address)
    }

    static func fromAddressToShippingLabelAddress(address: Address?) -> ShippingLabelAddress? {
        guard let address = address else { return nil }

        // In this way we support localized name correctly,
        // because the order is often reversed in a few Asian languages.
        var components = PersonNameComponents()
        components.givenName = address.firstName
        components.familyName = address.lastName

        let shippingLabelAddress = ShippingLabelAddress(company: address.company ?? "",
                                                        name: PersonNameComponentsFormatter.localizedString(from: components, style: .medium, options: []),
                                                        phone: address.phone ?? "",
                                                        country: address.country,
                                                        state: address.state,
                                                        address1: address.address1,
                                                        address2: address.address2 ?? "",
                                                        city: address.city,
                                                        postcode: address.postcode)
        return shippingLabelAddress
    }

    static func getStoredAccountSettings() -> AccountSettings? {
        let storageManager = ServiceLocator.storageManager

        let resultsController = ResultsController<StorageAccountSettings>(storageManager: storageManager, sortedBy: [])
        try? resultsController.performFetch()
        return resultsController.fetchedObjects.first
    }

    func updateValidatingAddressState(_ validating: Bool, type: ShipType) {
        switch type {
        case .origin:
            state.isValidatingOriginAddress = validating
        case .destination:
            state.isValidatingDestinationAddress = validating
        }
    }

    // Search the custom package based on the id
    //
    private func searchCustomPackage(id: String?) -> ShippingLabelCustomPackage? {
        guard let packagesResponse = packagesResponse,
              let packageID = id else {
            return nil
        }

        for customPackage in packagesResponse.customPackages {
            if customPackage.title == packageID {
                return customPackage
            }
        }

        return nil
    }

    // Search the predefined package based on the id
    //
    private func searchPredefinedPackage(id: String?) -> ShippingLabelPredefinedPackage? {
        guard let packagesResponse = packagesResponse,
              let packageID = id else {
            return nil
        }

        for option in packagesResponse.predefinedOptions {
            for predefinedPackage in option.predefinedPackages {
                if predefinedPackage.id == packageID {
                    return predefinedPackage
                }
            }
        }

        return nil
    }
}

// MARK: - Remote API
extension ShippingLabelFormViewModel {
    func validateAddress(type: ShipType, onCompletion: ((ValidationState, ShippingLabelAddressValidationSuccess?) -> ())? = nil) {

        guard let address = type == .origin ? originAddress : destinationAddress else { return }

        let addressToBeVerified = ShippingLabelAddressVerification(address: address, type: type)

        updateValidatingAddressState(true, type: type)

        let action = ShippingLabelAction.validateAddress(siteID: siteID, address: addressToBeVerified) { [weak self] (result) in

            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.updateValidatingAddressState(false, type: type)
                if response.isTrivialNormalization {
                    onCompletion?(.validated, response)
                } else {
                    onCompletion?(.suggestedAddress, response)
                }
            case .failure(let error):
                DDLogError("⛔️ Error validating shipping label address: \(error)")
                self.updateValidatingAddressState(false, type: type)
                if let error = error as? ShippingLabelAddressValidationError {
                    onCompletion?(.validationError(error), nil)
                } else {
                    onCompletion?(.genericError(error), nil)
                }
            }
        }
        stores.dispatch(action)
    }

    /// Syncs account settings specific to shipping labels, such as the last selected package and payment methods.
    ///
    func syncShippingLabelAccountSettings() {
        let action = ShippingLabelAction.synchronizeShippingLabelAccountSettings(siteID: order.siteID) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let value):
                self.handlePaymentMethodValueChanges(settings: value, editable: false)
            case .failure:
                DDLogError("⛔️ Error synchronizing shipping label account settings")
            }
        }
        stores.dispatch(action)
    }

    func syncPackageDetails() {
        let action = ShippingLabelAction.packagesDetails(siteID: order.siteID) { [weak self] result in
            switch result {
            case .success(let value):
                self?.packagesResponse = value
            case .failure:
                DDLogError("⛔️ Error synchronizing package details")
                return
            }
        }
        stores.dispatch(action)
    }

    enum ValidationState {
        case validated
        case suggestedAddress
        case validationError(ShippingLabelAddressValidationError)
        case genericError(Error)
    }
}

private extension ShippingLabelFormViewModel {
    enum Localization {
        static let packageDetailsPlaceholder = NSLocalizedString("Select the type of packaging you'd like to ship your items in",
                                                                 comment: "Placeholder in Shipping Label form for the Package Details row.")
        static let totalPackageWeight = NSLocalizedString("Total package weight: %1$@",
                                                          comment: "Total package weight label in Shipping Label form. %1$@ is a placeholder for the weight")
        static let carrierAndRatesPlaceholder = NSLocalizedString("Select your shipping carrier and rates",
                                                                  comment: "Placeholder in Shipping Label form for the Carrier and Rates row.")
        static let businessDaySingular = NSLocalizedString("%1$d business day",
                                                           comment: "Singular format of number of business day in Shipping Labels > Carrier and Rates")
        static let businessDaysPlural = NSLocalizedString("%1$d business days",
                                                          comment: "Plural format of number of business days in Shipping Labels > Carrier and Rates")
        static let paymentMethodPlaceholder = NSLocalizedString("Add a new credit card",
                                                                comment: "Placeholder in Shipping Label form for the Payment Method row.")
        static let paymentMethodLabel =
            NSLocalizedString("Credit card ending in %1$@",
                              comment: "Selected credit card in Shipping Label form. %1$@ is a placeholder for the last four digits of the credit card.")
        static let orderSummaryHeader = NSLocalizedString("Shipping label order summary",
                                                          comment: "Header of the order summary section in the shipping label creation form")
    }
}
