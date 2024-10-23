import Yosemite

final class WooShippingServiceViewModel: ObservableObject {
    /// View models to display available shipping rates.
    @Published private(set) var rates: [WooShippingServiceCardViewModel] = []

    init() {
        // TODO: Replace with real data from remote
        let rates = [ShippingLabelCarrierRate(title: "USPS - Media Mail",
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
        generateRates(for: rates)
    }

    /// Generates the view models to display available shipping rates.
    func generateRates(for rates: [ShippingLabelCarrierRate]) {
        self.rates = rates.map { WooShippingServiceCardViewModel(rate: $0 )}
    }
}
