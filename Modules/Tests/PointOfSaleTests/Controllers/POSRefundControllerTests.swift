import Testing
import Foundation
@testable import PointOfSale
import enum Yosemite.RefundAPIError
import struct Yosemite.POSOrder
import enum Yosemite.OrderRefundEligibilityFailure

@Suite(.timeLimit(.minutes(5)))
@MainActor
final class POSRefundControllerTests {
    private let refundSubmissionProcessor = MockPOSRefundSubmissionProcessor()
    private lazy var sut = POSRefundController(refundSubmissionProcessor: refundSubmissionProcessor)

    enum TestError: Error {
        case prepareRefundFailed
    }

    @Test func refundActionAvailability_when_order_is_completed_then_available() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(id: 1, status: .completed)

        // When / Then
        #expect(order.refundActionAvailability == .available)
    }

    @Test func refundActionAvailability_when_order_is_not_completed_then_unavailable() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(id: 1, status: .processing)

        // When / Then
        #expect(order.refundActionAvailability == .unavailable)
    }

    // MARK: - Refund Item Selection Tests

    @Test func preloadRefund_when_refund_is_available_then_preloads_without_opening_refund_flow() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(id: 1, status: .completed)

        // When
        await sut.preloadRefund(for: order)

        // Then
        #expect(refundSubmissionProcessor.preloadedOrderIDs == [order.id])
        #expect(sut.selectableItems.isEmpty)
        #expect(sut.reviewPreparationState == .idle)
    }

    @Test func preloadRefund_when_refund_is_unavailable_then_does_not_preload() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(id: 1, status: .processing)

        // When
        await sut.preloadRefund(for: order)

        // Then
        #expect(refundSubmissionProcessor.preloadedOrderIDs.isEmpty)
    }

    @Test func startRefundFlow_when_order_is_ineligible_then_returns_specific_failure() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder()
        refundSubmissionProcessor.prepareRefundErrorToThrow = OrderRefundEligibilityFailure.giftCardUnsupported

        // When
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        let result = await sut.startRefundFlow(for: order)

        // Then
        guard case .ineligible(.giftCardUnsupported) = result else {
            Issue.record("Expected the gift-card eligibility failure.")
            return
        }
    }

    @Test func test_startRefundFlow_when_preparation_has_custom_amount_then_returns_hasItemsToRefund() async throws {
        // Given
        let customAmount = POSOrderTestFactory.makePOSOrderCustomAmount(id: 777, name: "Discount Fee", total: 10, totalTax: 0)
        let order = POSOrderTestFactory.makeOrder(lineItems: [], customAmounts: [customAmount])

        // When
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        let availability = await sut.startRefundFlow(for: order)

        // Then
        #expect(availability == .hasItemsToRefund)
        #expect(sut.selectableItems.count == 1)
        #expect(sut.selectableItems.first?.isLumpSum == true)
    }

    @Test func toggleItemSelection_then_toggles_item_at_index() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)

        // When
        sut.toggleItemSelection(at: 0)
        let isSelectedAfterToggle = sut.selectableItems[0].isSelected

        // Then
        #expect(isSelectedAfterToggle == false)
    }

    @Test func toggleItemSelection_then_marks_refund_selection_as_modified() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, formattedPrice: "$10.00", formattedTotal: "$10.00")
        ])

        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        #expect(sut.hasModifiedSelection == false)

        // When
        sut.toggleItemSelection(at: 0)

        // Then
        #expect(sut.hasModifiedSelection == true)
    }

    @Test func toggleItemSelection_when_index_out_of_bounds_then_does_not_crash() async throws {
        // When
        let items = await MainActor.run {
            sut.toggleItemSelection(at: 999)
            return sut.selectableItems
        }

        // Then
        #expect(items.isEmpty)
    }

    @Test func clearSelection_then_removes_all_items() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        try #require(sut.selectableItems.count == 2)

        // When
        sut.clearSelection()

        // Then
        #expect(sut.selectableItems.isEmpty)
    }

    @Test func clearSelection_then_resets_modified_refund_selection() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, formattedPrice: "$10.00", formattedTotal: "$10.00")
        ])

        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        sut.toggleItemSelection(at: 0)
        try #require(sut.hasModifiedSelection == true)

        // When
        sut.clearSelection()

        // Then
        #expect(sut.hasModifiedSelection == false)
    }

    @Test func toggleAllItemsSelection_when_all_selected_then_deselects_all() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)

        // When
        sut.toggleAllItemsSelection()

        // Then
        try #require(sut.selectableItems.count == 2)
        for item in sut.selectableItems {
            #expect(item.isSelected == false)
        }
    }

    @Test func toggleAllItemsSelection_then_marks_refund_selection_as_modified() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        #expect(sut.hasModifiedSelection == false)

        // When
        sut.toggleAllItemsSelection()

        // Then
        #expect(sut.hasModifiedSelection == true)
    }

    @Test func toggleAllItemsSelection_when_some_deselected_then_selects_all() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        sut.toggleItemSelection(at: 0) // Deselect first item

        // When
        sut.toggleAllItemsSelection()

        // Then
        try #require(sut.selectableItems.count == 2)
        for item in sut.selectableItems {
            #expect(item.isSelected == true)
        }
    }

    @Test func toggleAllItemsSelection_when_none_selected_then_selects_all() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        sut.toggleAllItemsSelection() // Deselect all

        // When
        sut.toggleAllItemsSelection() // Should select all

        // Then
        try #require(sut.selectableItems.count == 2)
        for item in sut.selectableItems {
            #expect(item.isSelected == true)
        }
    }

    @Test func reset_then_clears_the_selection() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, formattedPrice: "$10.00", formattedTotal: "$10.00")
        ])

        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        sut.toggleItemSelection(at: 0)
        try #require(sut.hasModifiedSelection == true)
        try #require(sut.selectableItems.isNotEmpty)

        // When
        sut.reset()

        // Then
        #expect(sut.selectableItems.isEmpty)
        #expect(sut.hasModifiedSelection == false)

        // The pinned order is dropped: submitting after a reset fails instead of
        // refunding the previously selected order.
        await #expect(performing: {
            _ = try await sut.processRefund(reason: .none)
        }, throws: { error in
            (error as? POSRefundProcessingError) == .missingSelectedOrder
        })
    }

    // MARK: - Prepare Refund Review Data Tests

    @Test func prepareReview_when_no_items_selected_then_returns_preparationError() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, formattedPrice: "$10.00")
        ])

        // When
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        sut.toggleAllItemsSelection() // Deselect all

        // Then
        let result = await sut.prepareReview()
        #expect(result == .preparationError)
    }

    @Test func prepareReview_when_processor_succeeds_then_returns_its_review() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [POSOrderTestFactory.makePOSOrderItem(itemID: 42)])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        let expectedReview = refundSubmissionProcessor.reviewDataToReturn

        // When
        let result = await sut.prepareReview()

        // Then
        #expect(result == .ready(expectedReview))
        #expect(sut.reviewPreparationState == .idle)
    }

    @Test func prepareReview_when_one_item_deselected_then_previews_only_the_selected_item() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(id: 42, lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 7, quantity: 2)
        ])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        try #require(sut.selectableItems.count == 2)
        let selectedItemID = sut.selectableItems[1].id
        sut.toggleItemSelection(at: 0)

        // When
        _ = await sut.prepareReview()

        // Then
        #expect(refundSubmissionProcessor.spyReviewSelectedItems?.map(\.id) == [selectedItemID])
        #expect(refundSubmissionProcessor.spyReviewOrderID == 42)
        #expect(refundSubmissionProcessor.spyReviewReason == nil)
    }

    @Test func requiresCardPresentRefund_when_preparation_requires_card_present_refund_then_returns_true() async throws {
        // Given
        refundSubmissionProcessor.requiresCardPresentRefund = true
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

        // When
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)

        // Then
        #expect(sut.requiresCardPresentRefund == true)
    }

    // MARK: - Refund Review Preparation State

    @Test func prepareReview_when_processor_throws_then_state_is_previewError_and_retry_recovers() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        refundSubmissionProcessor.prepareReviewDataErrorToThrow = POSRefundSubmissionError.refundPreviewFailed

        // When
        let failedResult = await awaitReviewPreparation(sut)

        // Then the failure is returned and the inline-error state is published for the sheet
        #expect(failedResult == .previewError)
        #expect(sut.reviewPreparationState == .previewError())

        // When the failure is resolved and the user retries
        refundSubmissionProcessor.prepareReviewDataErrorToThrow = nil
        let recoveredResult = await awaitReviewPreparation(sut)

        // Then
        guard case .ready = recoveredResult else {
            Issue.record("Expected .ready after retry, got \(recoveredResult)")
            return
        }
        #expect(sut.reviewPreparationState == .idle)
    }

    @Test func prepareReview_when_processor_throws_typed_rejection_then_state_carries_its_message() async throws {
        // Given the preview was rejected with an actionable code (e.g. the order changed since loading)
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        refundSubmissionProcessor.prepareReviewDataErrorToThrow = RefundAPIError.quantityExceedsRefundable

        // When
        let result = await awaitReviewPreparation(sut)

        // Then the inline-error state carries the rejection's cashier-facing copy, and offers the
        // item reload rather than a retry that would be rejected the same way
        #expect(result == .previewError)
        #expect(sut.reviewPreparationState == .previewError(
            message: RefundAPIError.quantityExceedsRefundable.localizedDescription,
            recovery: .refreshItems
        ))
    }

    @Test func prepareReview_when_order_is_not_refundable_then_flow_ends_on_the_terminal_state() async throws {
        // Given the store reports the order as having nothing refundable left
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        refundSubmissionProcessor.prepareReviewDataErrorToThrow = RefundAPIError.orderNotRefundable

        // When
        let result = await awaitReviewPreparation(sut)

        // Then there is no selection to recover to, so the caller is told to end the flow
        #expect(result == .nothingToRefund)
        #expect(sut.reviewPreparationState == .idle)
    }

    @Test func refreshRefundableItems_when_the_reloaded_list_is_unchanged_then_clears_the_selection() async throws {
        // Given two refundable units, with only the first one selected
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, formattedPrice: "$10.00")
        ])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        sut.toggleItemSelection(at: 1)

        // When the reload returns the same list, as an order-level rejection does
        let result = await sut.refreshRefundableItems()

        // Then nothing is selected
        #expect(result == .hasItemsToRefund)
        #expect(sut.selectableItems.count == 2)
        #expect(sut.selectableItems.allSatisfy { !$0.isSelected })
    }

    @Test func refreshRefundableItems_when_preparation_has_fewer_items_then_replaces_items_and_clears_selection() async throws {
        // Given three refundable units, all selected
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 3, price: 10.00, formattedPrice: "$10.00")
        ])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)

        // When another register refunds one unit and preparation returns the two remaining rows.
        let remainingItems = Array(sut.selectableItems.dropFirst())
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order, selectableItems: remainingItems)
        let result = await sut.refreshRefundableItems()

        // Then the two remaining units are listed and none of them is selected
        #expect(result == .hasItemsToRefund)
        #expect(sut.selectableItems.map(\.id) == remainingItems.map(\.id))
        #expect(sut.selectableItems.allSatisfy { !$0.isSelected })
    }

    @Test func refreshRefundableItems_when_the_reload_fails_then_keeps_the_previously_loaded_items() async throws {
        // Given two refundable units, with only the first one selected
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, formattedPrice: "$10.00")
        ])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        sut.toggleItemSelection(at: 1)

        // When the reload fails, for example because the register lost connectivity
        refundSubmissionProcessor.prepareRefundErrorToThrow = NSError(domain: "test", code: 1)
        let result = await sut.refreshRefundableItems()

        // Then the previous list is still there, so a retry reloads instead of starting a new flow
        #expect(result == .failed)
        #expect(sut.selectableItems.count == 2)
        #expect(sut.hasLoadedSelectableItems == true)
    }

    @Test func hasLoadedSelectableItems_when_no_load_has_succeeded_then_is_false() async throws {
        // Given a controller with no refund flow started
        #expect(sut.hasLoadedSelectableItems == false)

        // When the first load fails
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])
        refundSubmissionProcessor.prepareRefundErrorToThrow = NSError(domain: "test", code: 1)
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)

        // Then
        #expect(sut.hasLoadedSelectableItems == false)
    }

    @Test func hasLoadedSelectableItems_when_the_flow_ends_then_is_false_again() async throws {
        // Given a loaded list of refundable items
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        #expect(sut.hasLoadedSelectableItems == true)

        // When the cashier dismisses the flow
        sut.clearSelection()

        // Then
        #expect(sut.hasLoadedSelectableItems == false)
    }

    @Test func refreshRefundableItems_then_hasModifiedRefundSelection_is_false_until_the_next_toggle() async throws {
        // Given a reloaded list with nothing selected
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, formattedPrice: "$10.00")
        ])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        sut.toggleItemSelection(at: 1)
        _ = await sut.refreshRefundableItems()

        // Then nothing of the cashier's is held, so switching orders needs no prompt
        #expect(sut.hasModifiedSelection == false)

        // When the cashier picks again
        sut.toggleItemSelection(at: 0)

        // Then the prompt applies again
        #expect(sut.hasModifiedSelection == true)
    }

    @Test func refreshRefundableItems_when_a_preview_error_is_shown_then_it_is_cleared() async throws {
        // Given a rejected preview
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        refundSubmissionProcessor.prepareReviewDataErrorToThrow = RefundAPIError.lineItemAlreadyRefunded
        _ = await awaitReviewPreparation(sut)

        // When the cashier reloads the refundable items
        refundSubmissionProcessor.prepareReviewDataErrorToThrow = nil
        _ = await sut.refreshRefundableItems()

        // Then the selection step is back to a clean state
        #expect(sut.reviewPreparationState == .idle)
    }

    @Test func prepareReview_when_selection_changes_mid_flight_then_result_is_dropped() async throws {
        // Given an order with two refundable units so a toggle is possible mid-flight
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, formattedPrice: "$10.00")
        ])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        refundSubmissionProcessor.onPrepareReviewDataCalled = { [weak sut] in
            sut?.toggleItemSelection(at: 0)
        }

        // When
        let result = await awaitReviewPreparation(sut)

        // Then the toggle superseded the preparation, and the stale result never advanced the state
        #expect(result == .superseded)
        #expect(sut.reviewPreparationState == .idle)
    }

    @Test func prepareReview_when_the_flow_is_reset_mid_flight_then_preparation_is_cancelled() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        refundSubmissionProcessor.onPrepareReviewDataCalled = { [weak sut] in
            sut?.reset()
        }

        // When
        let result = await awaitReviewPreparation(sut)

        // Then the reset cancelled the in-flight preparation and returned the state to idle
        #expect(result == .superseded)
        #expect(sut.reviewPreparationState == .idle)
    }

    @Test func prepareReview_when_no_preparation_loaded_then_returns_preparationError() async throws {
        // Given no selected order / no started refund flow

        // When
        let result = await sut.prepareReview()

        // Then
        #expect(result == .preparationError)
        #expect(sut.reviewPreparationState == .idle)
    }

    @Test func clearSelection_when_preview_failed_then_clears_the_error() async throws {
        // Given a completed preparation
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        refundSubmissionProcessor.prepareReviewDataErrorToThrow = POSRefundSubmissionError.refundPreviewFailed
        _ = await awaitReviewPreparation(sut)
        try #require(sut.reviewPreparationState == .previewError())

        // When
        sut.clearSelection()

        // Then
        #expect(sut.reviewPreparationState == .idle)
    }

    // MARK: - Process Refund Tests

    @Test func processRefund_then_submits_refund_with_correct_order_id() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(id: 123, lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)

        // When
        _ = try await sut.processRefund(reason: .none)

        // Then
        #expect(refundSubmissionProcessor.submitRefundCalled == true)
        #expect(refundSubmissionProcessor.spySubmitRefundOrderID == 123)
    }

    @Test func processRefund_then_submits_refund_with_selected_items() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, formattedPrice: "$10.00"),
            POSOrderTestFactory.makePOSOrderItem(itemID: 2, quantity: 1, price: 5.00, formattedPrice: "$5.00")
        ])

        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        sut.toggleItemSelection(at: 0) // Deselect first item of itemID 1

        // When
        _ = try await sut.processRefund(reason: .none)

        // Then
        let items = try #require(refundSubmissionProcessor.spySubmitRefundItems)
        #expect(items.count == 2)
        #expect(items.contains(where: { $0.itemID == 1 }))
        #expect(items.contains(where: { $0.itemID == 2 }))
    }

    @Test func processRefund_then_submits_refund_with_reason() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)

        // When
        _ = try await sut.processRefund(reason: "Customer changed their mind")

        // Then
        #expect(refundSubmissionProcessor.spySubmitRefundReason == "Customer changed their mind")
    }

    @Test func processRefund_when_successful_then_clears_selection() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, formattedPrice: "$10.00")
        ])

        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        try #require(sut.selectableItems.count == 2)

        // When
        _ = try await sut.processRefund(reason: .none)

        // Then
        #expect(sut.selectableItems.isEmpty)
    }

    @Test func processRefund_when_successful_then_returns_the_refunded_order_id() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(id: 321, lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)

        // When
        let result = try await sut.processRefund(reason: .none)

        // Then
        #expect(result.refundedOrderID == 321)
    }

    @Test func processRefund_when_successful_then_keeps_requiresCardPresentRefund_for_the_completion_screens() async throws {
        // Given a prepared flow that requires a card present refund
        refundSubmissionProcessor.requiresCardPresentRefund = true
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        try #require(sut.requiresCardPresentRefund)

        // When
        _ = try await sut.processRefund(reason: .none)

        // Then the completion screens can still read the preparation
        #expect(sut.requiresCardPresentRefund)
    }

    @Test func processRefund_when_submission_throws_then_propagates_error() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)

        struct TestError: Error {}
        refundSubmissionProcessor.submitRefundErrorToThrow = TestError()

        // When / Then
        var thrownError: Error?
        do {
            _ = try await sut.processRefund(reason: .none)
        } catch {
            thrownError = error
        }

        #expect(thrownError is TestError)
    }

    @Test func processRefund_when_no_refund_flow_was_started_then_throws_missingSelectedOrder() async throws {
        await #expect(performing: {
            _ = try await sut.processRefund(reason: .none)
        }, throws: { error in
            (error as? POSRefundProcessingError) == .missingSelectedOrder
        })
    }

    @Test func processRefund_when_refund_is_not_prepared_then_throws_missingRefundPreparation() async throws {
        // Given the flow was started for an order the store failed to prepare
        refundSubmissionProcessor.prepareRefundErrorToThrow = TestError.prepareRefundFailed
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)

        // When / Then
        await #expect(performing: {
            _ = try await sut.processRefund(reason: .none)
        }, throws: { error in
            (error as? POSRefundProcessingError) == .missingRefundPreparation
        })
    }

    @Test func processRefund_when_no_items_are_selected_then_throws_emptySelection() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        sut.toggleAllItemsSelection()

        // When / Then
        await #expect(performing: {
            _ = try await sut.processRefund(reason: .none)
        }, throws: { error in
            (error as? POSRefundProcessingError) == .emptySelection
        })
    }

    @Test func processRefund_when_refund_is_already_in_progress_then_throws_refundAlreadyInProgress() async throws {
        // Given
        let order = POSOrderTestFactory.makeOrder(lineItems: [
            POSOrderTestFactory.makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])
        refundSubmissionProcessor.preparationToReturn = makePreparation(for: order)
        _ = await sut.startRefundFlow(for: order)
        refundSubmissionProcessor.onSubmitRefund = {
            self.refundSubmissionProcessor.onSubmitRefund = nil
            await #expect(throws: POSRefundProcessingError.refundAlreadyInProgress) {
                _ = try await self.sut.processRefund(reason: .none)
            }
        }

        // When
        _ = try await sut.processRefund(reason: .none)

        // Then
        #expect(refundSubmissionProcessor.submitRefundCallCount == 1)
        #expect(sut.selectableItems.isEmpty)
    }

}

private extension POSRefundControllerTests {
    /// Runs review preparation and returns its outcome.
    @MainActor
    func awaitReviewPreparation(_ controller: POSRefundController) async -> POSRefundReviewPreparationResult {
        await controller.prepareReview()
    }

    /// Fixtures only: row expansion is not asserted by controller tests. The production
    /// adaptor and mapping own refund eligibility, quantities, totals, and formatting.
    func makePreparation(for order: POSOrder,
                         selectableItems: [POSRefundSelectableItem]? = nil) -> POSRefundPreparation {
        let items = selectableItems ?? order.lineItems.flatMap { item in
            (0..<NSDecimalNumber(decimal: item.quantity).intValue).map { index in
                POSRefundSelectableItem(from: item, isSelected: true, index: index)
            }
        } + order.customAmounts.map { POSRefundSelectableItem(from: $0, isSelected: true) }
        return POSRefundPreparation(orderID: order.id,
                                    selectableItems: items,
                                    paymentMethodDescription: "via Cash",
                                    customerEmail: nil,
                                    requiresCardPresentRefund: refundSubmissionProcessor.requiresCardPresentRefund)
    }
}
