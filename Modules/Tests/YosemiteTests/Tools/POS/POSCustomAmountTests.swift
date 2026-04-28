import Foundation
import Testing
import Fakes
@testable import Yosemite

struct POSCustomAmountTests {

    @Test func empty_cart_matches_nil_order() async throws {
        // Given
        let sut = [POSCustomAmount]()

        // When, Then
        #expect(sut.matches(order: nil) == true)
    }

    @Test func empty_cart_matches_order_with_no_fees() async throws {
        // Given
        let order = Order.fake()

        // When, Then
        #expect([POSCustomAmount]().matches(order: order) == true)
    }

    @Test func cart_with_custom_amount_does_not_match_order_with_no_fees() async throws {
        // Given
        let order = Order.fake()
        let sut = [POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: false)]

        // When, Then
        #expect(sut.matches(order: order) == false)
    }

    @Test func cart_with_custom_amount_matches_order_with_matching_fee() async throws {
        // Given
        let fee = OrderFeeLine.fake().copy(name: "Tip", total: "5.00")
        let order = Order.fake().copy(fees: [fee])
        let sut = [POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: false)]

        // When, Then
        #expect(sut.matches(order: order) == true)
    }

    @Test func cart_with_custom_amount_does_not_match_order_with_different_amount() async throws {
        // Given
        let fee = OrderFeeLine.fake().copy(name: "Tip", total: "10.00")
        let order = Order.fake().copy(fees: [fee])
        let sut = [POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: false)]

        // When, Then
        #expect(sut.matches(order: order) == false)
    }

    @Test func cart_with_custom_amount_does_not_match_order_with_different_name() async throws {
        // Given
        let fee = OrderFeeLine.fake().copy(name: "Service fee", total: "5.00")
        let order = Order.fake().copy(fees: [fee])
        let sut = [POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: false)]

        // When, Then
        #expect(sut.matches(order: order) == false)
    }

    @Test func cart_with_custom_amount_does_not_match_order_with_extra_fee() async throws {
        // Given
        let fee1 = OrderFeeLine.fake().copy(name: "Tip", total: "5.00")
        let fee2 = OrderFeeLine.fake().copy(name: "Delivery", total: "2.50")
        let order = Order.fake().copy(fees: [fee1, fee2])
        let sut = [POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: false)]

        // When, Then
        #expect(sut.matches(order: order) == false)
    }

    @Test func cart_with_multiple_custom_amounts_matches_order_with_all_fees() async throws {
        // Given
        let fee1 = OrderFeeLine.fake().copy(name: "Tip", total: "5.00")
        let fee2 = OrderFeeLine.fake().copy(name: "Delivery", total: "2.50")
        let order = Order.fake().copy(fees: [fee1, fee2])
        let sut = [
            POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: false),
            POSCustomAmount(name: "Delivery", amount: "2.50", isTaxable: false)
        ]

        // When, Then
        #expect(sut.matches(order: order) == true)
    }

    @Test func cart_with_duplicate_custom_amounts_matches_order_with_same_count_of_matching_fees() async throws {
        // Given
        let fee1 = OrderFeeLine.fake().copy(feeID: 1, name: "Tip", total: "5.00")
        let fee2 = OrderFeeLine.fake().copy(feeID: 2, name: "Tip", total: "5.00")
        let order = Order.fake().copy(fees: [fee1, fee2])
        let sut = [
            POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: false),
            POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: false)
        ]

        // When, Then
        #expect(sut.matches(order: order) == true)
    }

    @Test func cart_with_duplicate_custom_amounts_does_not_match_order_with_one_matching_fee() async throws {
        // Given
        let fee = OrderFeeLine.fake().copy(name: "Tip", total: "5.00")
        let order = Order.fake().copy(fees: [fee])
        let sut = [
            POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: false),
            POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: false)
        ]

        // When, Then
        #expect(sut.matches(order: order) == false)
    }

    @Test func cart_with_custom_amount_ignores_deleted_fees_in_order() async throws {
        // Given
        let liveFee = OrderFeeLine.fake().copy(name: "Tip", total: "5.00")
        let deletedFee = OrderFactory.deletedFeeLine(OrderFeeLine.fake().copy(feeID: 99, name: "Old", total: "10.00"))
        let order = Order.fake().copy(fees: [liveFee, deletedFee])
        let sut = [POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: false)]

        // When, Then
        #expect(sut.matches(order: order) == true)
    }
}
