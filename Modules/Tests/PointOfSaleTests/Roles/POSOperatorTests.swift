import Testing
@testable import PointOfSale

struct POSOperatorTests {
    @Test func test_hasCapability_when_operator_has_it_then_returns_true() {
        // Given
        let sut = POSOperator(displayName: "Jane", role: "pos_manager", capabilities: ["refund_shop_orders"])

        // When / Then
        #expect(sut.hasCapability(.refundShopOrders))
    }

    @Test func test_hasCapability_when_operator_lacks_it_then_returns_false() {
        // Given
        let sut = POSOperator(displayName: "Sam", role: "pos_cashier", capabilities: [])

        // When / Then
        #expect(sut.hasCapability(.refundShopOrders) == false)
    }
}
