import Testing
@testable import PointOfSale

struct POSOperatorTests {
    @Test func test_hasCapability_returns_true_when_present() {
        let op = POSOperator(userID: 1, displayName: "Jane", role: "pos_cashier",
                             capabilities: ["woocommerce_pos_access"], isAppAccountHolder: false)
        #expect(op.hasCapability("woocommerce_pos_access") == true)
    }

    @Test func test_hasCapability_returns_false_when_absent() {
        let op = POSOperator(userID: 1, displayName: "Jane", role: "pos_cashier",
                             capabilities: ["woocommerce_pos_access"], isAppAccountHolder: false)
        #expect(op.hasCapability("woocommerce_refund_orders") == false)
    }

    @Test func test_initials_from_full_name() {
        let op = POSOperator(userID: 1, displayName: "Jane Doe", role: "pos_cashier",
                             capabilities: [], isAppAccountHolder: false)
        #expect(op.initials == "JD")
    }

    @Test func test_initials_from_single_name() {
        let op = POSOperator(userID: 1, displayName: "Jane", role: "pos_cashier",
                             capabilities: [], isAppAccountHolder: false)
        #expect(op.initials == "J")
    }

    @Test func test_initials_from_empty_name() {
        let op = POSOperator(userID: 1, displayName: "", role: "pos_cashier",
                             capabilities: [], isAppAccountHolder: false)
        #expect(op.initials == "?")
    }
}
