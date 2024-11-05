import Yosemite

final class WooShippingServiceViewModel: ObservableObject {
    /// List of tabs to display for the shipping services.
    /// Contains the data about available shipping rates, grouped by carrier.
    @Published private(set) var serviceTabs: [WooShippingServiceTab] = []

    /// Selected shipping service rate.
    @Published private(set) var selectedRate: WooShippingSelectedRate?

    /// Available standard shipping rates.
    private var standardRates: [ShippingLabelCarrierRate] = []
    /// Available shipping rates with signature required.
    private var signatureRates: [ShippingLabelCarrierRate] = []
    /// Available shipping rates with adult signature required.
    private var adultSignatureRates: [ShippingLabelCarrierRate] = []

    /// Sort order for shipping services.
    @Published var sortOrder: SortOrder = .price

    init(standardRates: [ShippingLabelCarrierRate] = [],
         signatureRates: [ShippingLabelCarrierRate] = [],
         adultSignatureRates: [ShippingLabelCarrierRate] = []) {
        // TODO: Replace with real data from remote
        self.standardRates = standardRates
        self.signatureRates = signatureRates
        self.adultSignatureRates = adultSignatureRates
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
                        return WooShippingServiceCardViewModel(selected: selectedRate?.rate.title == rate.title,
                                                               signatureRequired: signature != nil && selectedRate?.signatureRate == signature,
                                                               adultSignatureRequired: adultSignature != nil && selectedRate?.adultSignatureRate == adultSignature,
                                                               rate: rate,
                                                               signatureRate: signature,
                                                               adultSignatureRate: adultSignature) { [weak self] rateTitle, signatureRequirement in
                            guard let self, let rate = standardRates.first(where: { $0.title == rateTitle }) else { return }
                            let signatureRate = signatureRequirement == .signatureRequired ? signatureRates.first(where: { $0.title == rateTitle }) : nil
                            let adultSignatureRate = signatureRequirement == .adultSignatureRequired ?
                                adultSignatureRates.first(where: { $0.title == rateTitle }) : nil
                            selectedRate = WooShippingSelectedRate(rate: rate,
                                                                   signatureRate: signatureRate,
                                                                   adultSignatureRate: adultSignatureRate)
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
