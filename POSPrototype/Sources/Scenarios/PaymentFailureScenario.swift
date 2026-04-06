import Foundation
import PointOfSale

struct PaymentFailureScenario: POSPrototypeScenario {
    var id: String { "payment-failure" }
    var name: String { "Payment Failure" }
    var description: String { "Card reader fails during payment processing" }
    var icon: String { "exclamationmark.triangle.fill" }

    func makeMockConfiguration() -> MockConfiguration {
        MockConfiguration(
            products: PrototypeCatalog.smallCafe,
            productLoadDelay: 0.2,
            paymentSequence: .failAtStep(.processing, message: "Card declined - insufficient funds"),
            initialReaderConnectionStatus: .connected(
                CardPresentPaymentCardReader(name: "Flaky Reader", batteryLevel: 0.30)
            ),
            orderSyncDelay: 0.3,
            taxRate: 0.08,
            storeName: "Test Store"
        )
    }
}
