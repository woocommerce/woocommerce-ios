import Yosemite

final class WooShippingServiceViewModel: ObservableObject {
    /// List of tabs to display for the shipping services.
    /// Contains the data about available shipping rates, grouped by carrier.
    @Published private(set) var serviceTabs: [WooShippingServiceTab] = []

    init() {
        // TODO: Replace with real data from remote
        let standardRates = [ShippingLabelCarrierRate(title: "USPS - Media Mail",
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
        let signatureRates = [ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
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
        let adultSignatureRates = [ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
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
        generateServiceTabs(from: standardRates, signatureRates: signatureRates, adultSignatureRates: adultSignatureRates)
    }

    /// Generates the data to display available shipping rates, grouped by carrier ID.
    private func generateServiceTabs(from standardRates: [ShippingLabelCarrierRate],
                                     signatureRates: [ShippingLabelCarrierRate],
                                     adultSignatureRates: [ShippingLabelCarrierRate]) {
        serviceTabs = standardRates.grouped(by: { $0.carrierID })
            .compactMap { (carrierID, rates) -> WooShippingServiceTab? in
                guard let carrier = WooShippingCarrier(rawValue: carrierID) else {
                    return nil
                }
                let cards = rates.map { rate in
                    let signature = signatureRates.first { rate.title == $0.title }
                    let adultSignature = adultSignatureRates.first { rate.title == $0.title }
                    return WooShippingServiceCardViewModel(rate: rate, signatureRate: signature, adultSignatureRate: adultSignature)
                }
                return WooShippingServiceTab(id: carrier, cards: cards)
            }
            .sorted(by: { $0.id < $1.id })
    }

    /// Holds the data needed to display a tab in `WooShippingServiceViewModel`.
    struct WooShippingServiceTab: Identifiable {
        let id: WooShippingCarrier
        let cards: [WooShippingServiceCardViewModel]
    }
}
