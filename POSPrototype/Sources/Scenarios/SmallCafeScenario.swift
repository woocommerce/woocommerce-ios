import Foundation
import PointOfSale

struct SimpleStoreScenario: POSPrototypeScenario {
    var id: String { "simple-store" }
    var name: String { "Simple Store" }
    var description: String { "5 products, reader connected - good starting point" }
    var icon: String { "storefront" }

    func makeMockConfiguration() -> MockConfiguration {
        MockConfiguration(
            products: PrototypeCatalog.smallCafe,
            productLoadDelay: 0.2,
            paymentSequence: .successAfterDelay(1.5),
            initialReaderConnectionStatus: .connected(
                CardPresentPaymentCardReader(name: "Reader", batteryLevel: 0.92)
            ),
            orderSyncDelay: 0.3,
            taxRate: 0.08,
            storeName: "Bean & Brew"
        )
    }
}

struct LargeCatalogScenario: POSPrototypeScenario {
    var id: String { "large-catalog" }
    var name: String { "Large Catalog" }
    var description: String { "20+ products - test scrolling, search, performance" }
    var icon: String { "square.grid.3x3" }

    func makeMockConfiguration() -> MockConfiguration {
        MockConfiguration(
            products: PrototypeCatalog.busyRetail,
            productLoadDelay: 0.4,
            paymentSequence: .successAfterDelay(2.0),
            initialReaderConnectionStatus: .connected(
                CardPresentPaymentCardReader(name: "Reader Pro", batteryLevel: 0.75)
            ),
            orderSyncDelay: 0.5,
            taxRate: 0.10,
            storeName: "TechGadgets"
        )
    }
}

struct NoReaderScenario: POSPrototypeScenario {
    var id: String { "no-reader" }
    var name: String { "No Card Reader" }
    var description: String { "Reader disconnected - test connection flows and cash" }
    var icon: String { "wifi.slash" }

    func makeMockConfiguration() -> MockConfiguration {
        MockConfiguration(
            products: PrototypeCatalog.smallCafe,
            productLoadDelay: 0.2,
            paymentSequence: .successAfterDelay(1.5),
            initialReaderConnectionStatus: .disconnected,
            orderSyncDelay: 0.3,
            taxRate: 0.08,
            storeName: "Corner Shop"
        )
    }
}

struct PhoneLayoutScenario: POSPrototypeScenario {
    var id: String { "phone-layout" }
    var name: String { "Phone Layout" }
    var description: String { "Minimal catalog, fast flow - for phone adaptation" }
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
