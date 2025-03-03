import Foundation
import Yosemite
import WooFoundation
import Combine
import struct Networking.WooShippingAccountSettings

/// Provides view data for `WooShippingCreateLabelsView`.
///
final class WooShippingCreateLabelsViewModel: ObservableObject {
    enum ContentState {
        case loading
        case ready
        case missingRequiredData
    }

    private let shippingSettingsService: ShippingSettingsService
    private let currencyFormatter: CurrencyFormatter
    private let itemsDataSource: WooShippingItemsDataSource
    private var destinationAddress: WooShippingAddress?
    private var destinationEmail: String?
    private let stores: StoresManager
    private var subscriptions: Set<AnyCancellable> = []
    private var debounceDuration: Double = 1

    let order: Order

    @Published private(set) var state = ContentState.loading

    /// The purchased shipping label.
    @Published private var shippingLabel: ShippingLabel?

    /// Whether a purchased shipping label can be viewed (and printed, tracked, refunded, etc.).
    var canViewLabel: Bool {
        shippingLabel != nil
    }

    /// Whether the custom information is completed or not.
    var customsInformationIsCompleted: Bool {
        customsForm != nil
    }

    /// View model for the section displayed after a shipping label is purchased.
    @Published private(set) var postPurchase: WooShippingPostPurchaseViewModel?

    /// View model for the items to ship.
    @Published private(set) var items: WooShippingItemsViewModel

    /// ID for the shipment.
    ///
    /// For now we support purchasing labels in a single shipment only, so we only need a single shipment ID.
    let shipmentID = "shipment_0"

    /// Selected package data for the shipping label.
    @Published private(set) var selectedPackage: WooShippingPackageDataRepresentable?

    /// String representing the total weight for the shipment.
    @Published var shipmentWeight: String = ""

    /// View model for the label shipping service.
    private(set) var shippingService: WooShippingServiceViewModel?

    /// Selected shipping rate when creating a shipping label.
    @Published private var selectedRate: WooShippingSelectedRate?

    /// View model for a list of origin addresses to ship from.
    private(set) var originAddresses = WooShippingOriginAddressListViewModel(addresses: [])

    /// Address to ship from (store address).
    @Published private var selectedOriginAddress: WooShippingOriginAddress?

    /// Address to ship from (store address), formatted for display.
    @Published private(set) var originAddress: String = ""

    /// Address to ship to (customer address), formatted for display and split into separate lines to allow additional formatting.
    var destinationAddressLines: [String]? {
        (destinationAddress?.formattedPostalAddress)?.components(separatedBy: ", ")
    }

    /// Possible statuses for a Woo Shipping destination address.
    enum DestinationAddressStatus {
        case verified
        case unverified
        case missing
    }

    /// The current destination address status.
    @Published private(set) var destinationAddressStatus: DestinationAddressStatus?

    /// This property can be set to display a notice with the provided label about the destination address status.
    @Published var destinationAddressStatusNoticeLabel: String?

    /// View model for address to edit.
    /// Setting this property will navigate to the address edit screen.
    @Published var addressToEdit: WooShippingEditAddressViewModel?

    /// Shipping lines for the order, with formatted amount.
    let shippingLines: [WooShipping_ShippingLineViewModel]

    /// Shipping rates for the purchased label, with formatted amount.
    var shippingRates: [(title: String, amount: String)] {
        if let shippingLabel {
            return [formatShippingRate(name: shippingLabel.serviceName, rate: shippingLabel.rate)]
        } else if let selectedRate {
            let baseRate = selectedRate.rate.rate
            let formattedBaseRate = formatShippingRate(name: Localization.baseRateLabel(for: selectedRate), rate: baseRate)
            let formattedSignatureRate = [
                selectedRate.signatureRate.map { self.formatShippingRate(name: Localization.signatureRequired, rate: $0.rate, basedOn: baseRate) },
                selectedRate.adultSignatureRate.map { self.formatShippingRate(name: Localization.adultSignatureRequired,
                                                                              rate: $0.rate,
                                                                              basedOn: baseRate) }
            ].compacted()
            return [formattedBaseRate] + formattedSignatureRate
        } else {
            return []
        }
    }

    /// Total cost of the shipping label, formatted for display.
    var totalCost: String? {
        guard let amount = shippingLabel?.rate ?? selectedRate?.totalRate else {
            return nil
        }
        return currencyFormatter.formatAmount(Decimal(amount))
    }

    private var isMissingStoreSettings: Bool {
        weightUnit.isEmpty && dimensionsUnit.isEmpty
    }

    /// Whether to mark the order as complete after the label is purchased.
    @Published var markOrderComplete: Bool = false

    /// If the purchase button should be enabled.
    var isPurchaseButtonEnabled: Bool {
        // Don't allow purchasing if a label is already purchased
        shippingLabel == nil
        // or if any required fields are missing
        && selectedOriginAddress != nil && destinationAddress != nil && selectedPackage != nil && selectedRate != nil
    }

    /// If the label purchase is in progress.
    @Published private(set) var isPurchasingLabel: Bool = false

    /// Unit to use for weight measurements.
    @Published var weightUnit = ""

    /// Unit to use for dimensions measurements.
    @Published var dimensionsUnit = ""

    /// Closure to execute after the label is successfully purchased.
    let onLabelPurchase: ((_ markOrderComplete: Bool) -> Void)?

    private var customsForm: ShippingLabelCustomsForm?

    lazy var customsFormViewModel: WooShippingCustomsFormViewModel = {
        WooShippingCustomsFormViewModel(order: order, onCompletion: { [weak self] form in
            self?.onCustomsFormFilled(form: form)
        })
    }()

    /// Check for the need of customs form
    ///
    var customsFormRequired: Bool {
        guard let originAddress = selectedOriginAddress,
              let destinationAddress = destinationAddress else {
            return false
        }
        return WooShippingCustomsRequirements.isCustomsRequired(originCountry: originAddress.country,
                                                                originState: originAddress.state,
                                                                destinationCountry: destinationAddress.country,
                                                                destinationState: destinationAddress.state)
    }

    /// Initialize the view model without an existing shipping label.
    init(order: Order,
         selectedOriginAddress: WooShippingOriginAddress? = nil,
         selectedPackage: WooShippingPackageDataRepresentable? = nil,
         selectedRate: WooShippingSelectedRate? = nil,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         shippingSettingsService: ShippingSettingsService = ServiceLocator.shippingSettingsService,
         userDefaults: UserDefaults = .standard,
         stores: StoresManager = ServiceLocator.stores,
         itemsDataSource: WooShippingItemsDataSource? = nil,
         debounceDuration: Double = 1,
         onLabelPurchase: ((Bool) -> Void)? = nil) {
        self.order = order
        let itemsDataSource = itemsDataSource ?? DefaultWooShippingItemsDataSource(order: order)
        self.itemsDataSource = itemsDataSource
        self.items = WooShippingItemsViewModel(dataSource: itemsDataSource)
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.onLabelPurchase = onLabelPurchase
        self.destinationAddress = Self.getDestinationAddress(order: order, address: order.shippingAddress)
        self.destinationEmail = order.shippingAddress?.email ?? order.billingAddress?.email
        self.shippingLines = order.shippingLines.map({ WooShipping_ShippingLineViewModel(shippingLine: $0, currency: order.currency) })
        self.selectedOriginAddress = selectedOriginAddress
        self.selectedPackage = selectedPackage
        self.selectedRate = selectedRate
        self.stores = stores
        self.debounceDuration = debounceDuration
        self.shippingSettingsService = shippingSettingsService

        loadDestinationAddress()
        observeSelectedOriginAddress()
        observeDestinationAddressStatus()
        observeSelectedPackage()
        observeForLabelRates()
        loadPackages()
        Task {
            await loadRequiredData()
        }
    }

    /// Initialize the view model from an existing shipping label.
    init(order: Order,
         shippingLabel: ShippingLabel,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         shippingSettingsService: ShippingSettingsService = ServiceLocator.shippingSettingsService,
         stores: StoresManager = ServiceLocator.stores) {
        self.order = order
        self.shippingLabel = shippingLabel
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.shippingSettingsService = shippingSettingsService
        self.postPurchase = WooShippingPostPurchaseViewModel(shippingLabel: shippingLabel)
        self.itemsDataSource = DefaultWooShippingItemsDataSource(order: order)
        self.items = WooShippingItemsViewModel(dataSource: itemsDataSource)
        self.shippingLines = order.shippingLines.map({ WooShipping_ShippingLineViewModel(shippingLine: $0, currency: order.currency) })
        self.originAddress = shippingLabel.originAddress.formattedPostalAddress?.replacingOccurrences(of: "\n", with: ", ") ?? ""
        self.destinationAddress = shippingLabel.destinationAddress.toWooShippingAddress()
        self.destinationAddressStatus = .verified
        self.onLabelPurchase = nil
        self.stores = stores
        Task {
            await loadRequiredData()
        }
    }

    @MainActor
    func loadRequiredData() async {
        state = .loading
        await withTaskGroup(of: Void.self) { group in
            if isMissingStoreSettings {
                group.addTask {
                    await self.loadStoreOptions()
                }
            }

            if originAddress.isEmpty {
                group.addTask {
                    await self.loadOriginAddresses()
                }
            }
        }

        if isMissingStoreSettings ||
            originAddress.isEmpty {
            state = .missingRequiredData
        } else {
            state = .ready
        }
    }

    /// Handles package selection for the shipping label.
    /// Selecting a package also refreshes the available rates for the shipping service.
    func selectPackage(_ packageData: WooShippingPackageDataRepresentable) {
        selectedPackage = packageData
    }

    /// Purchases a shipping label with the provided label details and settings.
    func purchaseLabel() {
        guard isPurchaseButtonEnabled, !isPurchasingLabel, let selectedOriginAddress, let destinationAddress, let selectedPackage, let selectedRate else {
            return
        }
        isPurchasingLabel = true
        let packagePurchase = WooShippingPackagePurchase(shipmentID: shipmentID,
                                                         package: fromPackageDataToPackageSelected(selectedPackage,
                                                                                                   weight: Double(shipmentWeight) ?? 0,
                                                                                                   shipmentID: shipmentID),
                                                         rate: selectedRate.purchaseRate,
                                                         productIDs: itemsDataSource.items.map(\.productOrVariationID))
        let action = WooShippingAction.purchaseShippingLabel(siteID: order.siteID,
                                                             orderID: order.orderID,
                                                             originAddress: selectedOriginAddress.toWooShippingAddress(),
                                                             destinationAddress: destinationAddress,
                                                             package: packagePurchase) { [weak self] result in
            guard let self else { return }
            isPurchasingLabel = false
            switch result {
            case .success(let shippingLabel):
                onLabelPurchase?(markOrderComplete)
                self.shippingLabel = shippingLabel
                postPurchase = WooShippingPostPurchaseViewModel(shippingLabel: shippingLabel)
            case .failure(let error):
                DDLogError("⛔️ Error purchasing shipping label: \(error)")
            }
        }
        stores.dispatch(action)
    }

    func onCustomsFormFilled(form: ShippingLabelCustomsForm) {
        customsForm = form
    }

    /// Sets the `addressToEdit` property for editing the destination address.
    /// After the address is edited, the destination address is replaced with the updated address.
    func editDestinationAddress() {
        addressToEdit = WooShippingEditAddressViewModel(address: destinationAddress,
                                                        orderID: order.orderID,
                                                        email: destinationEmail,
                                                        isVerified: destinationAddressStatus == .verified,
                                                        originCountryCode: selectedOriginAddress?.country,
                                                        originStateCode: selectedOriginAddress?.state,
                                                        onAddressEdited: { [weak self] editedAddress, editedEmail in
            guard let self else {
                return
            }
            destinationAddress = editedAddress
            destinationEmail = editedEmail
            destinationAddressStatus = .verified
            addressToEdit = nil // Dismisses address edit screen
        })
    }
}

// MARK: Remote
private extension WooShippingCreateLabelsViewModel {

    /// Updates store options (weight and dimensions units) with remote settings or fall back to cache results if failed.
    @MainActor
    func loadStoreOptions() async {
        let settings: WooShippingAccountSettings? = await withCheckedContinuation { continuation in
            let action = WooShippingAction.loadAccountSettings(siteID: order.siteID) { result in
                switch result {
                case .success(let settings):
                    continuation.resume(returning: settings)
                case .failure(let error):
                    DDLogError("⛔️ Error loading account settings: \(error)")
                    continuation.resume(returning: nil)
                }
            }
            stores.dispatch(action)
        }
        weightUnit = settings?.storeOptions.weightUnit ?? shippingSettingsService.weightUnit ?? ""
        dimensionsUnit = settings?.storeOptions.dimensionUnit ?? shippingSettingsService.dimensionUnit ?? ""
    }

    /// Syncs packages to use for shipping label from remote.
    ///
    func loadPackages() {
        let action = WooShippingAction.loadPackages(siteID: order.siteID) { result in
            if case .failure(let error) = result {
                DDLogError("⛔️ Error loading packages for Woo Shipping labels: \(error)")
            }
        }
        stores.dispatch(action)
    }

    /// Syncs origin addresses to use for shipping label from remote.
    ///
    @MainActor
    func loadOriginAddresses() async {
        let addresses = await withCheckedContinuation { continuation in
            let action = WooShippingAction.loadOriginAddresses(siteID: order.siteID) { result in
                switch result {
                case .success(let addresses):
                    continuation.resume(returning: addresses)
                case .failure(let error):
                    DDLogError("⛔️ Error loading origin addresses for Woo Shipping labels: \(error)")
                    continuation.resume(returning: [])
                }
            }
            stores.dispatch(action)
        }
        selectedOriginAddress = addresses.first(where: \.defaultAddress)
        originAddresses = WooShippingOriginAddressListViewModel(addresses: addresses,
                                                                selectedAddressID: selectedOriginAddress?.id)
        originAddresses.onSelect = { [weak self] selectedAddress in
            self?.selectedOriginAddress = selectedAddress
        }
    }

    /// Loads destination address of the order from remote.
    ///
    func loadDestinationAddress() {
        let action = WooShippingAction.verifyDestinationAddress(siteID: order.siteID,
                                                                orderID: order.orderID) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let address):
                destinationAddress = address.normalizedAddress.toWooShippingAddress()
                destinationAddressStatus = address.isVerified ? .verified : .unverified
            case .failure(let error):
                DDLogError("⛔️ Error loading destination addresses for Woo Shipping labels: \(error)")

                if let orderShippingAddress = Self.getDestinationAddress(order: order, address: order.shippingAddress) {
                    destinationAddress = orderShippingAddress
                    destinationAddressStatus = destinationAddressLines == nil ? .missing : .unverified
                } else {
                    destinationAddressStatus = .missing
                }
            }
        }
        stores.dispatch(action)
    }
}

// MARK: Utils
private extension WooShippingCreateLabelsViewModel {
    /// Observes the selected package and updates the shipment weight.
    func observeSelectedPackage() {
        let itemsWeight = itemsDataSource.items.map { $0.weight * Double(truncating: $0.quantity as NSDecimalNumber) }.reduce(0, +)
        $selectedPackage
            .map { selectedPackage in
                guard let selectedPackage else {
                    return itemsWeight.description
                }
                return (itemsWeight + (Double(selectedPackage.weight) ?? 0)).description
            }
            .assign(to: &$shipmentWeight)
    }

    /// Observes the selected origin address and updates the displayed origin address and shipping service.
    func observeSelectedOriginAddress() {
        $selectedOriginAddress
            .sink { [weak self] selectedOriginAddress in
                guard let self else { return }
                originAddress = selectedOriginAddress?.formattedPostalAddress ?? ""
                shippingService = WooShippingServiceViewModel(order: order,
                                                              originAddress: selectedOriginAddress?.toWooShippingAddress(),
                                                              destinationAddress: destinationAddress,
                                                              stores: stores) { [weak self] selectedRate in
                    self?.selectedRate = selectedRate
                }
            }
            .store(in: &subscriptions)
    }

    /// Observes the destination address status and updates the notice label.
    func observeDestinationAddressStatus() {
        /// Set the notice when the destination address status changes.
        $destinationAddressStatus
            .compactMap { $0 }
            .map { status in
                switch status {
                case .verified:
                    return Localization.DestinationAddressStatus.verified
                case .unverified:
                    return Localization.DestinationAddressStatus.unverified
                case .missing:
                    return Localization.DestinationAddressStatus.missing
                }
            }
            .assign(to: &$destinationAddressStatusNoticeLabel)

        /// Clear the notice after a delay when the address is verified.
        $destinationAddressStatusNoticeLabel
            .filter { $0 == Localization.DestinationAddressStatus.verified }
            .delay(for: .seconds(2), scheduler: RunLoop.current)
            .map { _ in nil }
            .assign(to: &$destinationAddressStatusNoticeLabel)
    }

    /// Observes the selected package and shipment weight and requests the available shipping rates.
    func observeForLabelRates() {
        $shipmentWeight
            .debounce(for: .seconds(debounceDuration), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .combineLatest($selectedPackage)
            .sink { [weak self] weight, selectedPackage in
                guard let self, let selectedPackage, let shippingService else { return }
                shippingService.loadLabelRates(for: fromPackageDataToPackageSelected(selectedPackage, weight: Double(weight) ?? 0, shipmentID: shipmentID))
            }
            .store(in: &subscriptions)
    }

    /// Provides the formatted label and amount for a shipping rate, based on the provided base rate.
    func formatShippingRate(name: String, rate: Double, basedOn baseRate: Double? = nil) -> (title: String, amount: String) {
        let amount = {
            guard let baseRate else {
                return rate
            }
            return rate - baseRate
        }()
        return (name, currencyFormatter.formatAmount(Decimal(amount)) ?? amount.description)
    }

    /// Gets the destination address as a `ShippingLabelAddress`.
    /// The order's billing phone is used as a fallback if there is no shipping phone.
    ///
    static func getDestinationAddress(order: Order, address: Address?) -> WooShippingAddress? {
        guard let phone = address?.phone, phone.isNotEmpty else {
            let destinationAddress = address?.copy(phone: order.billingAddress?.phone)
            return destinationAddress?.toWooShippingAddress()
        }
        return address?.toWooShippingAddress()
    }

    static func getStoredAccountSettings() -> AccountSettings? {
        let storageManager = ServiceLocator.storageManager

        let resultsController = ResultsController<StorageAccountSettings>(storageManager: storageManager, sortedBy: [])
        try? resultsController.performFetch()
        return resultsController.fetchedObjects.first
    }

    /// Converts the package data to a `ShippingLabelPackageSelected` object.
    func fromPackageDataToPackageSelected(_ packageData: WooShippingPackageDataRepresentable, weight: Double, shipmentID: String) -> ShippingLabelPackageSelected {
        ShippingLabelPackageSelected(id: shipmentID,
                                     boxID: packageData.id,
                                     length: Double(packageData.length) ?? 0,
                                     width: Double(packageData.width) ?? 0,
                                     height: Double(packageData.height) ?? 0,
                                     weight: weight,
                                     isLetter: WooShippingPackageType(rawValue: packageData.packageType) == .envelope,
                                     hazmatCategory: nil, // Hazmat support will be added in a future milestone
                                     customsForm: customsForm)
    }
}

private extension WooShippingCreateLabelsViewModel {
    enum Localization {
        static func baseRateLabel(for selectedRate: WooShippingSelectedRate) -> String {
            if selectedRate.signatureRate == nil && selectedRate.adultSignatureRate == nil {
                return selectedRate.rate.title
            } else {
                return String.localizedStringWithFormat(baseFeeFormat, selectedRate.rate.title)
            }
        }
        private static let baseFeeFormat = NSLocalizedString("wooShipping.createLabels.bottomSheet.baseFee",
                                                             value: "%1$@ (base fee)",
                                                             comment: "Label for row showing the base fee for the selected shipping service " +
                                                             "on the shipping label creation screen. Reads like: 'USPS - Media Mail (base fee)'")
        static let signatureRequired = NSLocalizedString("wooShipping.createLabels.bottomSheet.signatureRequired",
                                                         value: "Signature Required",
                                                         comment: "Label for row showing the additional cost to require a signature " +
                                                         "on the shipping label creation screen")
        static let adultSignatureRequired = NSLocalizedString("wooShipping.createLabels.bottomSheet.adultSignatureRequired",
                                                              value: "Adult Signature Required",
                                                              comment: "Label for row showing the additional cost to require an adult signature " +
                                                              "on the shipping label creation screen")

        enum DestinationAddressStatus {
            static let verified = NSLocalizedString("wooShipping.createLabels.addressVerification.destinationVerified",
                                                               value: "Verified destination address",
                                                               comment: "Notice when a destination address is verified on the shipping label creation screen")
            static let unverified = NSLocalizedString("wooShipping.createLabels.addressVerification.destinationUnverified",
                                                                 value: "Destination address unverified",
                                                                 comment: "Notice when a destination address is unverified on the shipping label creation screen")
            static let missing = NSLocalizedString("wooShipping.createLabels.addressVerification.destinationMissing",
                                                              value: "Destination address missing",
                                                              comment: "Notice when a destination address is missing on the shipping label creation screen")
        }
    }
}

private extension WooShippingOriginAddress {
    /// Converts the origin address to a `WooShippingAddress`.
    ///
    /// This prepares the address for use in e.g. fetching available shipping rates or purchasing the label.
    ///
    func toWooShippingAddress() -> WooShippingAddress {
        WooShippingAddress(company: company,
                           name: fullName,
                           phone: phone,
                           country: country,
                           state: state,
                           address1: address1,
                           address2: address2,
                           city: city,
                           postcode: postcode)
    }
}

private extension ShippingLabelAddress {
    /// Converts the address to a `WooShippingAddress`.
    ///
    /// This prepares the address for use as a destination address in the shipping label.
    ///
    func toWooShippingAddress() -> WooShippingAddress {
        WooShippingAddress(company: company,
                           name: name,
                           phone: phone,
                           country: country,
                           state: state,
                           address1: address1,
                           address2: address2,
                           city: city,
                           postcode: postcode)
    }
}

private extension Address {
    /// Converts the address to a `WooShippingAddress`.
    ///
    /// This prepares the address for use as a destination address in the shipping label.
    ///
    func toWooShippingAddress() -> WooShippingAddress {
        return WooShippingAddress(company: company ?? "",
                                  name: fullName,
                                  phone: phone ?? "",
                                  country: country,
                                  state: state,
                                  address1: address1,
                                  address2: address2 ?? "",
                                  city: city,
                                  postcode: postcode)
    }
}
