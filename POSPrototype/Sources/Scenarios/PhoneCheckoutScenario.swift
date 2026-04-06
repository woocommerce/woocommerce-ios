import Foundation
import PointOfSale

struct PhoneCheckoutScenario: POSPrototypeScenario {
    var id: String { "phone-checkout" }
    var name: String { "Phone Checkout" }
    var description: String { "Minimal catalog, fast flow - for phone layout testing" }
    var icon: String { "iphone" }

    func makeMockConfiguration() -> MockConfiguration {
        MockConfiguration(
            products: PrototypeCatalog.phoneMinimal,
            productLoadDelay: 0.1,
            paymentSequence: .successAfterDelay(1.0),
            initialReaderConnectionStatus: .connected(
                CardPresentPaymentCardReader(name: "Tap Reader", batteryLevel: 0.95)
            ),
            orderSyncDelay: 0.2,
            taxRate: 0.05,
            storeName: "Quick Shop"
        )
    }
}
