import Foundation
import PointOfSale

struct BusyRetailScenario: POSPrototypeScenario {
    var id: String { "busy-retail" }
    var name: String { "Busy Retail" }
    var description: String { "20+ products with variations, card reader" }
    var icon: String { "cart.fill" }

    func makeMockConfiguration() -> MockConfiguration {
        MockConfiguration(
            products: PrototypeCatalog.busyRetail,
            productLoadDelay: 0.5,
            paymentSequence: .successAfterDelay(2.0),
            initialReaderConnectionStatus: .connected(
                CardPresentPaymentCardReader(name: "Retail Reader Pro", batteryLevel: 0.75)
            ),
            orderSyncDelay: 0.6,
            taxRate: 0.10,
            storeName: "TechGadgets Store"
        )
    }
}
