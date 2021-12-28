import XCTest
@testable import WooCommerce

final class PaymentLinkBuilderTests: XCTestCase {

    func test_link_is_built_with_the_correct_parameters() {
        // Given
        let builder = PaymentLinkBuilder(host: "https://www.test-store.com",
                                         orderID: 123,
                                         orderKey: "wc-456")

        // When
        let paymentLink = builder.build()

        // Then
        XCTAssertEqual(paymentLink, "https://www.test-store.com/checkout/order-pay/123/?pay_for_order=true&key=wc-456")
    }
}
