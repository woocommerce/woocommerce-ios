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
    private(set) var originAddress: ShippingLabelAddress?
    private(set) var destinationAddress: ShippingLabelAddress?
    let orderItems: [OrderItem]
    let currency: String

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

    init(siteID: Int64,
         originAddress: Address?,
         destinationAddress: Address?,
         items: [OrderItem],
         currency: String,
         stores: StoresManager = ServiceLocator.stores) {

        self.siteID = siteID
        self.orderItems = items
        self.currency = currency

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

    private static func generateInitialSections() -> [Section] {
        let shipFrom = Row(type: .shipFrom, dataState: .pending, displayMode: .editable)
        let shipTo = Row(type: .shipTo, dataState: .pending, displayMode: .disabled)
        let packageDetails = Row(type: .packageDetails, dataState: .pending, displayMode: .disabled)
        let shippingCarrierAndRates = Row(type: .shippingCarrierAndRates, dataState: .pending, displayMode: .disabled)
        let paymentMethod = Row(type: .paymentMethod, dataState: .pending, displayMode: .disabled)
        let rows: [Row] = [shipFrom, shipTo, packageDetails, shippingCarrierAndRates, paymentMethod]
        return [Section(rows: rows)]
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

        state.sections = [Section(rows: rows)]
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
}

// MARK: - Remote API
extension ShippingLabelFormViewModel {
    func validateAddress(type: ShipType, onCompletion: ((ValidationState, ShippingLabelAddressValidationResponse?) -> ())? = nil) {

        guard let address = type == .origin ? originAddress : destinationAddress else { return }

        let addressToBeVerified = ShippingLabelAddressVerification(address: address, type: type)

        updateValidatingAddressState(true, type: type)

        let action = ShippingLabelAction.validateAddress(siteID: siteID, address: addressToBeVerified) { [weak self] (result) in

            guard let self = self else { return }
            switch result {
            case .success:
                let response = try? result.get()

                // No errors, the address is validated
                if response?.errors == nil && response?.isTrivialNormalization == true {
                    self.updateValidatingAddressState(false, type: type)
                    onCompletion?(.validated, response)
                }
                // No errors, but there is a suggested address
                else if response?.errors == nil && response?.isTrivialNormalization == false {
                    self.updateValidatingAddressState(false, type: type)
                    onCompletion?(.suggestedAddress, response)
                }
                // There are some address validation errors
                else {
                    self.updateValidatingAddressState(false, type: type)
                    onCompletion?(.validationError, response)
                }
            case .failure(let error):
                DDLogError("⛔️ Error validating shipping label address: \(error)")
                self.updateValidatingAddressState(false, type: type)
                onCompletion?(.genericError, nil)
            }
        }
        stores.dispatch(action)
    }

    enum ValidationState {
        case validated
        case suggestedAddress
        case validationError
        case genericError
    }
}
