import Foundation
import Yosemite
import WooFoundation

/// Provides view data for `WooShippingCreateLabelsView`.
///
final class WooShippingCreateLabelsViewModel: ObservableObject {
    private let currencyFormatter: CurrencyFormatter
    private let order: Order
    private let itemsDataSource: WooShippingItemsDataSource
    private let originSiteAddress: ShippingLabelAddress?
    private let destinationAddress: ShippingLabelAddress?
    private let stores: StoresManager

    /// The purchased shipping label.
    @Published private var shippingLabel: ShippingLabel?

    /// Whether a purchased shipping label can be viewed (and printed, tracked, refunded, etc.).
    var canViewLabel: Bool {
        shippingLabel != nil
    }

    /// View model for the section displayed after a shipping label is purchased.
    @Published private(set) var postPurchase: WooShippingPostPurchaseViewModel?

    /// View model for the items to ship.
    @Published private(set) var items: WooShippingItemsViewModel

    /// Selected package for the shipping label.
    @Published private(set) var selectedPackage: ShippingLabelPackageSelected? {
        didSet {
            if let selectedPackage {
                shippingService = WooShippingServiceViewModel(order: order,
                                                              originAddress: originSiteAddress,
                                                              destinationAddress: destinationAddress,
                                                              selectedPackage: selectedPackage) { [weak self] selectedRate in
                    self?.selectedRate = selectedRate
                }
            }
        }
    }

    /// View model for the label shipping service.
    private(set) var shippingService: WooShippingServiceViewModel?

    /// Selected shipping rate when creating a shipping label.
    private var selectedRate: WooShippingSelectedRate?

    /// Address to ship from (store address), formatted for display.
    private(set) lazy var originAddress: String = {
        originSiteAddress?.formattedPostalAddress?.replacingOccurrences(of: "\n", with: ", ") ?? ""
    }()

    /// Address to ship to (customer address), formatted for display and split into separate lines to allow additional formatting.
    private(set) lazy var destinationAddressLines: [String] = {
        (destinationAddress?.formattedPostalAddress ?? "").components(separatedBy: .newlines)
    }()

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

    /// Whether to mark the order as complete after the label is purchased.
    @Published var markOrderComplete: Bool = false

    /// If the purchase button should be enabled.
    var isPurchaseButtonEnabled: Bool {
        selectedRate != nil && shippingLabel == nil
    }

    /// If the label purchase is in progress.
    @Published private(set) var isPurchasingLabel: Bool = false

    /// Closure to execute after the label is successfully purchased.
    let onLabelPurchase: ((_ markOrderComplete: Bool) -> Void)?

    /// Initialize the view model without an existing shipping label.
    init(order: Order,
         originAddress: SiteAddress? = nil,
         selectedPackage: ShippingLabelPackageSelected? = nil,
         selectedRate: WooShippingSelectedRate? = nil,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         userDefaults: UserDefaults = .standard,
         stores: StoresManager = ServiceLocator.stores,
         onLabelPurchase: ((Bool) -> Void)? = nil) {
        self.order = order
        self.itemsDataSource = DefaultWooShippingItemsDataSource(order: order)
        self.items = WooShippingItemsViewModel(dataSource: itemsDataSource)
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.onLabelPurchase = onLabelPurchase
        let accountSettings = Self.getStoredAccountSettings()
        let company = ServiceLocator.stores.sessionManager.defaultSite?.name
        let defaultAccount = ServiceLocator.stores.sessionManager.defaultAccount
        self.originSiteAddress = Self.getDefaultOriginAddress(accountSettings: accountSettings,
                                                              company: company,
                                                              siteAddress: originAddress ?? SiteAddress(),
                                                              account: defaultAccount,
                                                              userDefaults: userDefaults)
        self.destinationAddress = Self.getDestinationAddress(order: order, address: order.shippingAddress)
        self.shippingLines = order.shippingLines.map({ WooShipping_ShippingLineViewModel(shippingLine: $0) })
        self.selectedPackage = selectedPackage
        self.selectedRate = selectedRate
        self.stores = stores
    }

    /// Initialize the view model from an existing shipping label.
    init(order: Order,
         shippingLabel: ShippingLabel,
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         stores: StoresManager = ServiceLocator.stores) {
        self.order = order
        self.shippingLabel = shippingLabel
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.postPurchase = WooShippingPostPurchaseViewModel(shippingLabel: shippingLabel)
        self.itemsDataSource = DefaultWooShippingItemsDataSource(order: order)
        self.items = WooShippingItemsViewModel(dataSource: itemsDataSource)
        self.shippingLines = order.shippingLines.map({ WooShipping_ShippingLineViewModel(shippingLine: $0) })
        self.originSiteAddress = shippingLabel.originAddress
        self.destinationAddress = shippingLabel.destinationAddress
        self.onLabelPurchase = nil
        self.stores = stores
    }

    /// Purchases a shipping label with the provided label details and settings.
    func purchaseLabel() {
        guard isPurchaseButtonEnabled, !isPurchasingLabel, let originSiteAddress, let destinationAddress, let selectedPackage, let selectedRate else {
            return
        }
        isPurchasingLabel = true
        // For now we support purchasing labels in a single shipment only.
        // In future milestones we can create an array of `WooShippingPackagePurchase` with unique shipment IDs for each shipment.
        let package = WooShippingPackagePurchase(shipmentID: "shipment_0",
                                                 package: selectedPackage,
                                                 rate: selectedRate.purchaseRate,
                                                 productIDs: itemsDataSource.items.map(\.productOrVariationID))
        let action = WooShippingAction.purchaseShippingLabel(siteID: order.siteID,
                                                             orderID: order.orderID,
                                                             originAddress: originSiteAddress,
                                                             destinationAddress: destinationAddress,
                                                             package: package) { [weak self] result in
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
}

// MARK: Utils
private extension WooShippingCreateLabelsViewModel {
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

    // We generate the default origin address using the information
    // of the logged Account and of the website.
    static func getDefaultOriginAddress(accountSettings: AccountSettings?,
                                        company: String?,
                                        siteAddress: SiteAddress,
                                        account: Account?,
                                        userDefaults: UserDefaults) -> ShippingLabelAddress? {
        let address = Address(firstName: accountSettings?.firstName ?? "",
                              lastName: accountSettings?.lastName ?? "",
                              company: company ?? "",
                              address1: siteAddress.address,
                              address2: siteAddress.address2,
                              city: siteAddress.city,
                              state: siteAddress.state,
                              postcode: siteAddress.postalCode,
                              country: siteAddress.countryCode.rawValue,
                              phone: userDefaults[.storePhoneNumber] ?? "",
                              email: account?.email)
        return fromAddressToShippingLabelAddress(address: address)
    }

    /// Gets the destination address as a `ShippingLabelAddress`.
    /// The order's billing phone is used as a fallback if there is no shipping phone.
    ///
    static func getDestinationAddress(order: Order, address: Address?) -> ShippingLabelAddress? {
        guard let phone = address?.phone, phone.isNotEmpty else {
            let destinationAddress = address?.copy(phone: order.billingAddress?.phone)
            return fromAddressToShippingLabelAddress(address: destinationAddress)
        }
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
    }
}
