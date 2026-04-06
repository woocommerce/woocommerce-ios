import Foundation
import PointOfSale

struct SmallCafeScenario: POSPrototypeScenario {
    var id: String { "small-cafe" }
    var name: String { "Small Cafe" }
    var description: String { "5 products, card reader connected, fast payment" }
    var icon: String { "cup.and.saucer.fill" }

    func makeMockConfiguration() -> MockConfiguration {
        MockConfiguration(
            products: PrototypeCatalog.smallCafe,
            productLoadDelay: 0.3,
            paymentSequence: .successAfterDelay(1.5),
            initialReaderConnectionStatus: .connected(
                CardPresentPaymentCardReader(name: "Cafe Reader", batteryLevel: 0.92)
            ),
            orderSyncDelay: 0.4,
            taxRate: 0.08,
            storeName: "Bean & Brew Cafe",
            currencyCode: "USD"
        )
    }
}
