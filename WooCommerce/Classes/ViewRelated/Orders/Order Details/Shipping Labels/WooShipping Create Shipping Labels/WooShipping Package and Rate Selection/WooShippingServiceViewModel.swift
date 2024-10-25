import Yosemite

final class WooShippingServiceViewModel: ObservableObject {
    /// List of tabs to display for the shipping services.
    /// Contains the data about available shipping rates, grouped by carrier.
    @Published private(set) var serviceTabs: [WooShippingServiceTab] = []

    /// Selected standard shipping service rate.
    private(set) var selectedStandardRate: ShippingLabelCarrierRate?
    /// Selected signature shipping service rate (if signature is required).
    private(set) var selectedSignatureRate: ShippingLabelCarrierRate?
    /// Selected adult signature shipping service rate (if adult signature is required).
    private(set) var selectedAdultSignatureRate: ShippingLabelCarrierRate?

    /// Available standard shipping rates.
    private let standardRates: [ShippingLabelCarrierRate]
    /// Available shipping rates with signature required.
    private let signatureRates: [ShippingLabelCarrierRate]
    /// Available shipping rates with adult signature required.
    private let adultSignatureRates: [ShippingLabelCarrierRate]

    /// Sort order for shipping services.
    @Published var sortOrder: SortOrder = .price

    init() {
        // TODO: Replace with real data from remote
        standardRates = [ShippingLabelCarrierRate(title: "USPS - Media Mail",
                                              insurance: "100",
                                              retailRate: 8,
                                              rate: 7.53,
                                              rateID: "rate_a8a29d5f34984722942f466c30ea27ef",
                                              serviceID: "",
                                              carrierID: "usps",
                                              shipmentID: "",
                                              hasTracking: true,
                                              isSelected: false,
                                              isPickupFree: true,
                                              deliveryDays: 7,
                                              deliveryDateGuaranteed: false),
                     ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
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
        signatureRates = [ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
                                                       insurance: "100",
                                                       retailRate: 42.76,
                                                       rate: 42.76,
                                                       rateID: "rate_a8a29d5f34984722942f466c30ea27ei",
                                                       serviceID: "",
                                                       carrierID: "usps",
                                                       shipmentID: "",
                                                       hasTracking: true,
                                                       isSelected: false,
                                                       isPickupFree: true,
                                                       deliveryDays: 2,
                                                       deliveryDateGuaranteed: false)]
        adultSignatureRates = [ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
                                                            insurance: "100",
                                                            retailRate: 46.96,
                                                            rate: 46.96,
                                                            rateID: "rate_a8a29d5f34984722942f466c30ea27ej",
                                                            serviceID: "",
                                                            carrierID: "usps",
                                                            shipmentID: "",
                                                            hasTracking: true,
                                                            isSelected: false,
                                                            isPickupFree: true,
                                                            deliveryDays: 2,
                                                            deliveryDateGuaranteed: false)]
        generateServiceTabs()
    }

    /// Sorts the shipping services by the provided sort order.
    func sortShipping(by order: SortOrder) {
        sortOrder = order
        generateServiceTabs()
    }

    /// Generates the data to display available shipping rates, grouped by carrier ID.
    private func generateServiceTabs() {
        serviceTabs = standardRates.grouped(by: { $0.carrierID })
            .compactMap { (carrierID, rates) -> WooShippingServiceTab? in
                guard let carrier = WooShippingCarrier(rawValue: carrierID) else {
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
                        return WooShippingServiceCardViewModel(selected: selectedStandardRate?.title == rate.title,
                                                               signatureRequired: signature != nil && selectedSignatureRate == signature,
                                                               adultSignatureRequired: adultSignature != nil && selectedAdultSignatureRate == adultSignature,
                                                               rate: rate,
                                                               signatureRate: signature,
                                                               adultSignatureRate: adultSignature) { [weak self] rateTitle, signatureRequirement in
                            guard let self else { return }
                            let standardRate = standardRates.first(where: { $0.title == rateTitle })
                            let signatureRate = signatureRates.first(where: { $0.title == rateTitle })
                            let adultSignatureRate = adultSignatureRates.first(where: { $0.title == rateTitle })
                            switch signatureRequirement {
                            case .none:
                                selectedStandardRate = standardRate
                                selectedSignatureRate = nil
                                selectedAdultSignatureRate = nil
                            case .signatureRequired:
                                selectedStandardRate = standardRate
                                selectedSignatureRate = signatureRate
                                selectedAdultSignatureRate = nil
                            case .adultSignatureRequired:
                                selectedStandardRate = standardRate
                                selectedSignatureRate = nil
                                selectedAdultSignatureRate = adultSignatureRate
                            }
                            self.generateServiceTabs()
                        }
                    }
                return WooShippingServiceTab(id: carrier, cards: cards)
            }
            .sorted(by: { $0.id < $1.id })
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
}

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
