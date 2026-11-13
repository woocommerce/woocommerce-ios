import Testing
@testable import PointOfSale
import struct Yosemite.POSCustomAmount

struct POSCustomAmountFlowTests {
    private let customAmount = POSCustomAmount(name: "Service fee", amount: "10.00", isTaxable: false)

    @Test func test_add_when_read_then_has_no_editing_amount_and_add_mode() {
        // Given
        let flow = POSCustomAmountFlow.add

        // When
        let editingCustomAmount = flow.editingCustomAmount
        let mode = flow.analyticsMode

        // Then
        #expect(editingCustomAmount == nil)
        #expect(mode == .add)
    }

    @Test func test_edit_when_read_then_returns_edited_amount_and_edit_mode() {
        // Given
        let flow = POSCustomAmountFlow.edit(customAmount)

        // When
        let editingCustomAmount = flow.editingCustomAmount
        let mode = flow.analyticsMode

        // Then
        #expect(editingCustomAmount == customAmount)
        #expect(mode == .edit)
    }

    @Test func test_id_when_flows_differ_then_ids_differ() {
        // Given
        let otherCustomAmount = POSCustomAmount(name: "Delivery", amount: "5.00", isTaxable: true)

        // When
        let ids = [
            POSCustomAmountFlow.add.id,
            POSCustomAmountFlow.edit(customAmount).id,
            POSCustomAmountFlow.edit(otherCustomAmount).id
        ]

        // Then
        #expect(Set(ids).count == ids.count)
    }
}
