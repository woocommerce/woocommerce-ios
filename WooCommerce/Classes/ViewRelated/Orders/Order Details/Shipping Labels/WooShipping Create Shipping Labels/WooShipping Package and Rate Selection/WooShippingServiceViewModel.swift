import Combine
import Experiments
import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// Provides view data for `WooShippingServiceView`.
///
final class WooShippingServiceViewModel: ObservableObject {
    private let siteID: Int64
    private let orderID: Int64
    private let originAddress: WooShippingAddress?
    private let destinationAddress: WooShippingAddress?
    private let stores: StoresManager
    private let analytics: Analytics
    private let featureFlagService: FeatureFlagService

    /// List of tabs to display for the shipping services.
    /// Contains the data about available shipping rates, grouped by carrier.
    @Published private(set) var serviceTabs: [WooShippingServiceTab] = []

    @Published var selectedTabIndex: Int = 0

    @Published private(set) var displayedServiceCards: [WooShippingServiceCardViewModel] = []

    /// Selected shipping service rate.
    @Published private(set) var selectedRate: WooShippingSelectedRate?

    /// Whether the destination address is present and with non-empty fields.
    private var hasDestinationAddress: Bool {
        destinationAddress?.formattedPostalAddress != nil
    }

    /// Selected shipping service package.
    private(set) var selectedPackage: ShippingLabelPackageSelected?

    /// State of loading shipping rates.
    @Published private(set) var loadingState: LabelRatesState = .empty

    /// Available standard shipping rates.
    private var standardRates: [ShippingLabelCarrierRate] = []
    /// Available shipping rates with signature required.
    private var signatureRates: [ShippingLabelCarrierRate] = []
    /// Available shipping rates with adult signature required.
    private var adultSignatureRates: [ShippingLabelCarrierRate] = []

    /// Additional rates
    private var carbonNeutralRates: [ShippingLabelCarrierRate] = []
    private var saturdayDeliveryRates: [ShippingLabelCarrierRate] = []
    private var additionalHandlingRates: [ShippingLabelCarrierRate] = []

    /// Sort order for shipping services.
    @Published var sortOrder: SortOrder = .price

    /// Closure to execute after a rate is selected.
    let onSelectRate: ((_ selectedRate: WooShippingSelectedRate) -> Void)?

    init(order: Order,
         originAddress: WooShippingAddress?,
         destinationAddress: WooShippingAddress?,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         onSelectRate: ((_ selectedRate: WooShippingSelectedRate) -> Void)? = nil) {
        self.siteID = order.siteID
        self.orderID = order.orderID
        self.originAddress = originAddress
        self.destinationAddress = destinationAddress
        self.stores = stores
        self.analytics = analytics
        self.featureFlagService = featureFlagService
        self.onSelectRate = onSelectRate
        observeSelectedTab()
    }

    /// Sorts the shipping services by the provided sort order.
    func sortShipping(by order: SortOrder) {
        sortOrder = order
        generateServiceTabs()
    }

    /// Selects the rate with the given title and signature requirement.
    func selectRate(_ rate: ShippingLabelCarrierRate,
                    signatureRate: ShippingLabelCarrierRate?,
                    adultSignatureRate: ShippingLabelCarrierRate?,
                    carbonNeutralRate: ShippingLabelCarrierRate?,
                    saturdayDeliveryRate: ShippingLabelCarrierRate?,
                    additionalHandlingRate: ShippingLabelCarrierRate?) {
        let selectedRate = WooShippingSelectedRate(rate: rate,
                                                   signatureRate: signatureRate,
                                                   adultSignatureRate: adultSignatureRate,
                                                   carbonNeutralRate: carbonNeutralRate,
                                                   saturdayDeliveryRate: saturdayDeliveryRate,
                                                   additionalHandlingRate: additionalHandlingRate)
        self.selectedRate = selectedRate
        generateServiceTabs()
        onSelectRate?(selectedRate)
        analytics.track(event: .WooShipping.rateSelectionStep(state: .selected))
    }

    /// Clears the selected rate.
    func clearSelectedRate() {
        selectedRate = nil
    }

    func refreshSelectedRate(from oldRate: WooShippingSelectedRate) -> WooShippingSelectedRate? {
        let updatedStandardRate = standardRates.first(where: {
            $0.serviceID == oldRate.rate.serviceID
        })
        let updatedSignatureRate = signatureRates.first(where: {
            $0.serviceID == oldRate.signatureRate?.serviceID
        })
        let updatedAdultSignatureRate = adultSignatureRates.first(where: {
            $0.serviceID == oldRate.adultSignatureRate?.serviceID
        })
        let updatedCarbonNeutralRate = carbonNeutralRates.first(where: {
            $0.serviceID == oldRate.carbonNeutralRate?.serviceID
        })
        let updatedSaturdayDeliveryRate = saturdayDeliveryRates.first(where: {
            $0.serviceID == oldRate.saturdayDeliveryRate?.serviceID
        })
        let updatedAdditionalHandlingRate = additionalHandlingRates.first(where: {
            $0.serviceID == oldRate.additionalHandlingRate?.serviceID
        })
        guard let updatedStandardRate else {
            return nil
        }
        let newSelectedRate = WooShippingSelectedRate(rate: updatedStandardRate,
                                                      signatureRate: updatedSignatureRate,
                                                      adultSignatureRate: updatedAdultSignatureRate,
                                                      carbonNeutralRate: updatedCarbonNeutralRate,
                                                      saturdayDeliveryRate: updatedSaturdayDeliveryRate,
                                                      additionalHandlingRate: updatedAdditionalHandlingRate)
        self.selectedRate = newSelectedRate
        generateServiceTabs()
        return newSelectedRate
    }

    /// Retrieves shipping label rates for this shipment from remote.
    func loadLabelRates(for selectedPackage: ShippingLabelPackageSelected,
                        onLoadingCompletion: @escaping (Result<Void, Swift.Error>) -> Void = { _ in }) {
        // Store the selected package for retrying if error occurs
        self.selectedPackage = selectedPackage

        guard let originAddress, let destinationAddress, hasDestinationAddress else {
            onLoadingCompletion(.failure(Error.missingDestinationAddress))
            return updateLoadingState(to: .error(Error.missingDestinationAddress))
        }

        guard selectedPackage.weight > 0 else {
            onLoadingCompletion(.failure(Error.missingShipmentWeight))
            return updateLoadingState(to: .error(Error.missingShipmentWeight))
        }

        updateLoadingState(to: .loading)
        let action = WooShippingAction.loadLabelRates(siteID: siteID,
                                                      orderID: orderID,
                                                      originAddress: originAddress,
                                                      destinationAddress: destinationAddress,
                                                      packages: [selectedPackage]) { [weak self] remotePackages, result in
            guard let self,
                  /// Avoids showing the obsolete rates if the user changes the package weight while loading.
                  [self.selectedPackage] == remotePackages else {
                onLoadingCompletion(.success(()))
                return
            }

            switch result {
            case let .success(rates):
                guard let rates = rates.first(where: { $0.packageID == selectedPackage.id }),
                      rates.defaultRates.isNotEmpty else {
                    DDLogError("⛔️ Fetched shipping label rates for Woo Shipping do not include rates for selected package: \(selectedPackage)")
                    let isHAZMAT = selectedPackage.hazmatCategory != nil
                    let error = Error.noRatesAvailable(isHAZMAT: isHAZMAT)
                    updateLoadingState(to: .error(error))
                    analytics.track(event: .WooShipping.rateSelectionStep(state: .loadingFailed, error: error))
                    onLoadingCompletion(.failure(error))
                    return
                }

                standardRates = rates.defaultRates
                signatureRates = rates.signatureRequired
                adultSignatureRates = rates.adultSignatureRequired
                carbonNeutralRates = rates.carbonNeutral
                saturdayDeliveryRates = rates.saturdayDelivery
                additionalHandlingRates = rates.additionalHandling
                updateLoadingState(to: .loaded)
                analytics.track(event: .WooShipping.rateSelectionStep(state: .loadingSuccess))
                onLoadingCompletion(.success(()))
            case let .failure(error):
                DDLogError("⛔️ Error loading shipping label rates for Woo Shipping: \(error)")
                updateLoadingState(to: .error(Error.failedLoadingLabelRates))
                analytics.track(event: .WooShipping.rateSelectionStep(state: .loadingFailed, error: error))
                onLoadingCompletion(.failure(Error.failedLoadingLabelRates))
            }
        }
        stores.dispatch(action)
    }
}

extension WooShippingServiceViewModel {
    /// Holds the data needed to display a tab in `WooShippingServiceViewModel`.
    struct WooShippingServiceTab: Identifiable {
        let id: WooShippingCarrier
        let cards: [WooShippingServiceCardViewModel]
    }

    /// Options for sorting available shipping services.
    enum SortOrder: CaseIterable {
        case price
        case deliveryTime

        var displayName: String {
            switch self {
            case .price:
                Localization.sortByPrice
            case .deliveryTime:
                Localization.sortByDeliveryTime
            }
        }
    }

    /// States for label rates.
    enum LabelRatesState: Equatable {
        case empty
        case loading
        case loaded
        case error(_ error: Error)
    }

    enum Error: Swift.Error, Equatable {
        case missingDestinationAddress
        case missingShipmentWeight
        case failedLoadingLabelRates
        case noRatesAvailable(isHAZMAT: Bool)
    }
}

// MARK: Utils
private extension WooShippingServiceViewModel {
    /// Generates the data to display available shipping rates, grouped by carrier ID.
    func generateServiceTabs() {
        serviceTabs = standardRates.grouped(by: { $0.carrierID })
            .compactMap { (carrierID, rates) -> WooShippingServiceTab? in
                guard let carrier = WooShippingCarrier(rawValue: carrierID) else {
                    return nil
                }
                if carrier == .fedex && !featureFlagService.isFeatureFlagEnabled(.wooShippingFedEx) {
                    return nil
                }
                let cards = rates
                    .sorted(by: { lhs, rhs in
                        switch sortOrder {
                        case .price:
                            return lhs.rate < rhs.rate
                        case .deliveryTime:
                            guard let lhsDeliveryDays = lhs.deliveryDays, let rhsDeliveryDays = rhs.deliveryDays else {
                                return lhs.deliveryDays != nil // Sort rates with nil delivery days to the end of the list
                            }
                            return lhsDeliveryDays < rhsDeliveryDays
                        }
                    })
                    .map { rate in
                        let signature = signatureRates.first { rate.title == $0.title }
                        let adultSignature = adultSignatureRates.first { rate.title == $0.title }
                        let carbonNeutral = carbonNeutralRates.first { rate.title == $0.title }
                        let saturdayDelivery = saturdayDeliveryRates.first { rate.title == $0.title }
                        let additionalHandling = additionalHandlingRates.first { rate.title == $0.title }
                        return WooShippingServiceCardViewModel(
                            selected: selectedRate?.rate.title == rate.title,
                            signatureRequired: signature != nil && selectedRate?.signatureRate == signature,
                            adultSignatureRequired: adultSignature != nil && selectedRate?.adultSignatureRate == adultSignature,
                            carbonNeutralSelected: carbonNeutral != nil && selectedRate?.carbonNeutralRate == carbonNeutral,
                            saturdayDeliverySelected: saturdayDelivery != nil && selectedRate?.saturdayDeliveryRate == saturdayDelivery,
                            additionalHandlingSelected: additionalHandling != nil && selectedRate?.additionalHandlingRate == additionalHandling,
                            rate: rate,
                            signatureRate: signature,
                            adultSignatureRate: adultSignature,
                            carbonNeutralRate: carbonNeutral,
                            saturdayDeliveryRate: saturdayDelivery,
                            additionalHandlingRate: additionalHandling
                        ) { [weak self] rateTitle, signatureRequirement, carbonNeutral, saturdayDelivery, additionalHandling in
                            guard let self, let rate = standardRates.first(where: { $0.title == rateTitle }) else { return }
                            let signatureRate = signatureRequirement == .signatureRequired ? signatureRates.first(where: { $0.title == rateTitle }) : nil
                            let adultSignatureRate = signatureRequirement == .adultSignatureRequired ?
                            adultSignatureRates.first(where: { $0.title == rateTitle }) : nil
                            let carbonNeutralRate = carbonNeutral ? carbonNeutralRates.first(where: { $0.title == rateTitle }) : nil
                            let saturdayDeliveryRate = saturdayDelivery ? saturdayDeliveryRates.first(where: { $0.title == rateTitle }) : nil
                            let additionalHandlingRate = additionalHandling ? additionalHandlingRates.first(where: { $0.title == rateTitle }) : nil
                            selectRate(rate,
                                       signatureRate: signatureRate,
                                       adultSignatureRate: adultSignatureRate,
                                       carbonNeutralRate: carbonNeutralRate,
                                       saturdayDeliveryRate: saturdayDeliveryRate,
                                       additionalHandlingRate: additionalHandlingRate)
                        }
                    }
                return WooShippingServiceTab(id: carrier, cards: cards)
            }
            .sorted(by: { $0.id < $1.id })
    }

    /// Updates view model for provided loading state.
    func updateLoadingState(to state: LabelRatesState) {
        switch state {
        case .loading:
            standardRates = Self.placeholderRates
            generateServiceTabs()
        case .loaded:
            generateServiceTabs()
        case .empty, .error:
            serviceTabs = []
        }
        loadingState = state
    }

    func observeSelectedTab() {
        $serviceTabs.combineLatest($selectedTabIndex)
            .map { tabs, index in
                tabs[safe: index]?.cards ?? []
            }
            .assign(to: &$displayedServiceCards)
    }
}

// MARK: Constants
private extension WooShippingServiceViewModel {
    enum Localization {
        static let sortByPrice = NSLocalizedString("wooShipping.createLabels.rates.sortBy.price",
                                                   value: "Cheapest",
                                                   comment: "Option to sort shipping rates by price in the shipping label creation screen.")
        static let sortByDeliveryTime = NSLocalizedString("wooShipping.createLabels.rates.sortBy.deliveryTime",
                                                          value: "Fastest",
                                                          comment: "Option to sort shipping rates by delivery time in the shipping label creation screen.")
    }
}

// MARK: Placeholder data
private extension WooShippingServiceViewModel {
    /// Placeholder data to use while loading rates from remote.
    static var placeholderRates: [ShippingLabelCarrierRate] {
        [ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
                                 insurance: "100",
                                 retailRate: 40.06,
                                 rate: 40.06,
                                 rateID: "rate_a8a29d5f34984722942f466c30ea27eh",
                                 serviceID: "",
                                 carrierID: "usps",
                                 shipmentID: "",
                                 hasTracking: true,
                                 isSelected: false,
                                 isPickupFree: true,
                                 deliveryDays: 2,
                                 deliveryDateGuaranteed: false),
         ShippingLabelCarrierRate(title: "DHL - Next Day",
                                  insurance: "100",
                                  retailRate: 15,
                                  rate: 14.22,
                                  rateID: "rate_a8a29d5f34984722942f466c30ea27eg",
                                  serviceID: "",
                                  carrierID: "dhlexpress",
                                  shipmentID: "",
                                  hasTracking: true,
                                  isSelected: false,
                                  isPickupFree: true,
                                  deliveryDays: 1,
                                  deliveryDateGuaranteed: false)]
    }
}
