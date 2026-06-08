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

    @Test func empty_cart_matches_order_with_remote_added_fee() async throws {
        // Given
        let fee = OrderFeeLine.fake().copy(name: "Plugin fee", total: "2.50")
        let order = Order.fake().copy(fees: [fee])

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

    @Test func cart_with_custom_amount_matches_order_with_extra_remote_added_fee() async throws {
        // Given
        let fee1 = OrderFeeLine.fake().copy(name: "Tip", total: "5.00")
        let fee2 = OrderFeeLine.fake().copy(name: "Delivery", total: "2.50")
        let order = Order.fake().copy(fees: [fee1, fee2])
        let sut = [POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: false)]

        // When, Then
        #expect(sut.matches(order: order) == true)
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

    /// Locks in the documented behaviour on `[POSCustomAmount].matches(order:)`: matching
    /// is on `(name, amount)` only, not `isTaxable`. The server's tax decision can legitimately
    /// differ from the cart's intent (tax-exempt customer, store-level tax-class override),
    /// and treating a divergence as a mismatch would force a redundant resync every time.
    @Test(arguments: [
        (cartTaxable: true, orderTaxStatus: OrderFeeTaxStatus.taxable),
        (cartTaxable: true, orderTaxStatus: .none),
        (cartTaxable: false, orderTaxStatus: .taxable),
        (cartTaxable: false, orderTaxStatus: .none)
    ])
    func cart_matches_order_regardless_of_tax_status_when_name_and_amount_align(
        cartTaxable: Bool,
        orderTaxStatus: OrderFeeTaxStatus
    ) async throws {
        // Given
        let fee = OrderFeeLine.fake().copy(name: "Tip", taxStatus: orderTaxStatus, total: "5.00")
        let order = Order.fake().copy(fees: [fee])
        let sut = [POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: cartTaxable)]

        // When, Then
        #expect(sut.matches(order: order) == true)
    }

    // MARK: - taxableIntentMatches

    @Test func taxableIntentMatches_when_both_empty_then_returns_true() async throws {
        // Given
        let sut = [POSCustomAmount]()

        // When, Then
        #expect(sut.taxableIntentMatches([]) == true)
    }

    @Test func taxableIntentMatches_when_same_amount_with_same_taxable_flag_then_returns_true() async throws {
        // Given
        let id = UUID()
        let previous = [POSCustomAmount(id: id, name: "Tip", amount: "5.00", isTaxable: true)]
        let sut = [POSCustomAmount(id: id, name: "Tip", amount: "5.00", isTaxable: true)]

        // When, Then
        #expect(sut.taxableIntentMatches(previous) == true)
    }

    @Test func taxableIntentMatches_when_taxable_flag_toggled_on_same_amount_then_returns_false() async throws {
        // Given
        let id = UUID()
        let previous = [POSCustomAmount(id: id, name: "Tip", amount: "5.00", isTaxable: false)]
        let sut = [POSCustomAmount(id: id, name: "Tip", amount: "5.00", isTaxable: true)]

        // When, Then
        #expect(sut.taxableIntentMatches(previous) == false)
    }

    @Test func taxableIntentMatches_when_count_differs_then_returns_false() async throws {
        // Given
        let previous = [POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: true)]
        let sut = [
            POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: true),
            POSCustomAmount(name: "Delivery", amount: "2.50", isTaxable: true)
        ]

        // When, Then
        #expect(sut.taxableIntentMatches(previous) == false)
    }

    @Test func taxableIntentMatches_when_ids_differ_then_returns_false() async throws {
        // Given a same-valued amount that is a different instance (new id) than the synced one
        let previous = [POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: true)]
        let sut = [POSCustomAmount(name: "Tip", amount: "5.00", isTaxable: true)]

        // When, Then
        #expect(sut.taxableIntentMatches(previous) == false)
    }

    @Test func taxableIntentMatches_when_multiple_amounts_all_unchanged_then_returns_true() async throws {
        // Given
        let id1 = UUID()
        let id2 = UUID()
        let previous = [
            POSCustomAmount(id: id1, name: "Tip", amount: "5.00", isTaxable: true),
            POSCustomAmount(id: id2, name: "Delivery", amount: "2.50", isTaxable: false)
        ]
        let sut = [
            POSCustomAmount(id: id2, name: "Delivery", amount: "2.50", isTaxable: false),
            POSCustomAmount(id: id1, name: "Tip", amount: "5.00", isTaxable: true)
        ]

        // When, Then
        #expect(sut.taxableIntentMatches(previous) == true)
    }

    @Test func taxableIntentMatches_when_one_of_several_amounts_toggled_then_returns_false() async throws {
        // Given
        let id1 = UUID()
        let id2 = UUID()
        let previous = [
            POSCustomAmount(id: id1, name: "Tip", amount: "5.00", isTaxable: true),
            POSCustomAmount(id: id2, name: "Delivery", amount: "2.50", isTaxable: false)
        ]
        let sut = [
            POSCustomAmount(id: id1, name: "Tip", amount: "5.00", isTaxable: true),
            POSCustomAmount(id: id2, name: "Delivery", amount: "2.50", isTaxable: true)
        ]

        // When, Then
        #expect(sut.taxableIntentMatches(previous) == false)
    }

    /// Guards against a false match when `self` carries a duplicate `id`. With ids `[A, A]`
    /// against a previous `[A, B]`, the counts and tax flags align, but `B` has silently
    /// disappeared. The duplicate must be treated as a mismatch so the caller re-syncs.
    @Test func taxableIntentMatches_when_self_has_duplicate_ids_then_returns_false() async throws {
        // Given
        let idA = UUID()
        let idB = UUID()
        let previous = [
            POSCustomAmount(id: idA, name: "Tip", amount: "5.00", isTaxable: true),
            POSCustomAmount(id: idB, name: "Delivery", amount: "2.50", isTaxable: true)
        ]
        let sut = [
            POSCustomAmount(id: idA, name: "Tip", amount: "5.00", isTaxable: true),
            POSCustomAmount(id: idA, name: "Delivery", amount: "2.50", isTaxable: true)
        ]

        // When, Then
        #expect(sut.taxableIntentMatches(previous) == false)
    }

    /// Mirror of the above: a duplicate `id` on the `previous` side must also be rejected.
    @Test func taxableIntentMatches_when_previous_has_duplicate_ids_then_returns_false() async throws {
        // Given
        let idA = UUID()
        let idB = UUID()
        let previous = [
            POSCustomAmount(id: idA, name: "Tip", amount: "5.00", isTaxable: true),
            POSCustomAmount(id: idA, name: "Delivery", amount: "2.50", isTaxable: true)
        ]
        let sut = [
            POSCustomAmount(id: idA, name: "Tip", amount: "5.00", isTaxable: true),
            POSCustomAmount(id: idB, name: "Delivery", amount: "2.50", isTaxable: true)
        ]

        // When, Then
        #expect(sut.taxableIntentMatches(previous) == false)
    }
}
