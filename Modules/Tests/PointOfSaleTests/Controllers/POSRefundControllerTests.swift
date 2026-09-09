import Testing
import TestKit
import Foundation
@testable import PointOfSale
import enum Yosemite.RefundAPIError
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import enum Yosemite.OrderRefundEligibilityFailure
@testable import struct Yosemite.POSRefund
@testable import struct Yosemite.POSRefundItem
import struct Yosemite.POSOrderRefund
@testable import struct Yosemite.POSRefundsResult
import class WooFoundation.CurrencySettings
import class WooFoundation.CurrencyFormatter

@Suite(.timeLimit(.minutes(5)))
final class POSRefundControllerTests {
    private let refundsService = MockPOSRefundsService()
    private lazy var currencySettingsProvider = MockCurrencySettingsProvider()
    private lazy var currencyFormatter = CurrencyFormatter(currencySettings: currencySettingsProvider.currencySettings)
    private lazy var refundSubmissionProcessor = MockPOSRefundSubmissionProcessor(refundsService: refundsService,
                                                                                  currencyFormatter: currencyFormatter)
    private lazy var sut = POSRefundController(refundSubmissionProcessor: refundSubmissionProcessor)

    enum TestError: Error {
        case prepareRefundFailed
    }

    @MainActor
    @Test func refundActionAvailability_when_completed_order_selected_then_available() async throws {
        // Given
        let order = makeOrder(id: 1)

        // When

        // Then
        #expect(sut.refundActionAvailability(for: order) == .available)
    }

    @MainActor
    @Test func refundActionAvailability_when_no_order_then_unavailable() async throws {
        // When / Then
        #expect(sut.refundActionAvailability(for: nil) == .unavailable)
    }

    @MainActor
    @Test func refundActionAvailability_when_order_completed_then_available() async throws {
        // Given
        let order = makeOrder(id: 1, status: .completed)

        // When

        // Then
        #expect(sut.refundActionAvailability(for: order) == .available)
    }

    @MainActor
    @Test func refundActionAvailability_when_order_not_completed_then_unavailable() async throws {
        // Given
        let order = makeOrder(id: 1, status: .processing)

        // When

        // Then
        #expect(sut.refundActionAvailability(for: order) == .unavailable)
    }

    // MARK: - Refund Item Selection Tests

    @MainActor
    @Test func preloadRefund_when_refund_is_available_then_preloads_without_opening_refund_flow() async throws {
        // Given
        let order = makeOrder(id: 1, status: .completed)

        // When
        await sut.preloadRefund(for: order)

        // Then
        #expect(refundSubmissionProcessor.preloadedOrderIDs == [order.id])
        #expect(sut.selectableItems.isEmpty)
        #expect(sut.reviewPreparationState == .idle)
    }

    @MainActor
    @Test func preloadRefund_when_refund_is_unavailable_then_does_not_preload() async throws {
        // Given
        let order = makeOrder(id: 1, status: .processing)

        // When
        await sut.preloadRefund(for: order)

        // Then
        #expect(refundSubmissionProcessor.preloadedOrderIDs.isEmpty)
    }

    @MainActor
    @Test func startRefundFlow_when_product_has_multiple_quantities_then_creates_one_row_per_unit() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, name: "Item A", quantity: 3, formattedPrice: "$10.00", formattedTotal: "$30.00"),
            makePOSOrderItem(itemID: 2, name: "Item B", quantity: 1, formattedPrice: "$5.00")
        ])

        // When
        _ = await sut.startRefundFlow(for: order)

        // Then
        #expect(sut.selectableItems.count == 4)
    }

    @MainActor
    @Test func startRefundFlow_then_all_items_are_selected_by_default() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        // When
        _ = await sut.startRefundFlow(for: order)

        // Then
        #expect(sut.selectableItems.count == 2)
        for item in sut.selectableItems {
            #expect(item.isSelected)
        }
    }

    @MainActor
    @Test func startRefundFlow_when_order_is_ineligible_then_returns_specific_failure() async throws {
        // Given
        let order = makeOrder()
        refundSubmissionProcessor.prepareRefundErrorToThrow = OrderRefundEligibilityFailure.giftCardUnsupported

        // When
        let result = await sut.startRefundFlow(for: order)

        // Then
        guard case .ineligible(.giftCardUnsupported) = result else {
            Issue.record("Expected the gift-card eligibility failure.")
            return
        }
    }

    @MainActor
    @Test func startRefundFlow_when_item_partially_refunded_then_excludes_refunded_quantity() async throws {
        // Given: Order has 3 units of item, 1 was previously refunded
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [POSRefund(items: [POSRefundItem(refundedItemID: 1, quantity: -1, name: "", formattedPrice: "", formattedTotal: "", imageSrc: nil)])],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 3, formattedPrice: "$10.00", formattedTotal: "$30.00")
        ])

        // When
        _ = await sut.startRefundFlow(for: order)

        // Then: Should only show 2 available (3 - 1 refunded)
        #expect(sut.selectableItems.count == 2)
    }

    @MainActor
    @Test func startRefundFlow_when_item_fully_refunded_then_excludes_item_entirely() async throws {
        // Given: Order has 2 units of item, both were previously refunded
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [POSRefund(items: [POSRefundItem(refundedItemID: 1, quantity: -2, name: "", formattedPrice: "", formattedTotal: "", imageSrc: nil)])],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00"),
            makePOSOrderItem(itemID: 2, quantity: 1, formattedPrice: "$5.00")
        ])

        // When
        _ = await sut.startRefundFlow(for: order)

        // Then: Should only show item 2 (item 1 is fully refunded)
        #expect(sut.selectableItems.count == 1)
        #expect(sut.selectableItems[0].itemID == 2)
    }

    @MainActor
    @Test func test_startRefundFlow_when_order_has_custom_amount_then_appends_lump_sum_selectable() async throws {
        // Given
        let customAmount = makePOSOrderCustomAmount(id: 777, name: "Discount Fee", total: 10, totalTax: 0)
        let order = makeOrder(
            lineItems: [makePOSOrderItem(itemID: 1, quantity: 1, formattedPrice: "$10.00")],
            customAmounts: [customAmount]
        )

        // When
        _ = await sut.startRefundFlow(for: order)

        // Then
        #expect(sut.selectableItems.count == 2)
        let feeRow = try #require(sut.selectableItems.first(where: { $0.isLumpSum }))
        #expect(feeRow.itemID == 777)
        #expect(feeRow.name == "Discount Fee")
        #expect(feeRow.lineItemTotal == 10)
        #expect(feeRow.originalQuantity == 1)
        #expect(feeRow.isSelected == true)
    }

    @MainActor
    @Test func test_startRefundFlow_when_custom_amount_already_refunded_then_excludes_fee() async throws {
        // Given
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [POSRefund(items: [POSRefundItem(refundedItemID: 777, quantity: 0, name: "Discount Fee",
                                                     formattedPrice: "", formattedTotal: "", imageSrc: nil, isLumpSum: true)])],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )
        let customAmount = makePOSOrderCustomAmount(id: 777, name: "Discount Fee", total: 10, totalTax: 0)
        let order = makeOrder(
            lineItems: [makePOSOrderItem(itemID: 1, quantity: 1, formattedPrice: "$10.00")],
            customAmounts: [customAmount]
        )

        // When
        _ = await sut.startRefundFlow(for: order)

        // Then
        #expect(sut.selectableItems.count == 1)
        #expect(sut.selectableItems.contains(where: { $0.isLumpSum }) == false)
    }

    @MainActor
    @Test func test_startRefundFlow_with_only_unrefunded_custom_amount_then_returns_hasItemsToRefund() async throws {
        // Given
        let customAmount = makePOSOrderCustomAmount(id: 777, name: "Discount Fee", total: 10, totalTax: 0)
        let order = makeOrder(lineItems: [], customAmounts: [customAmount])

        // When
        let availability = await sut.startRefundFlow(for: order)

        // Then
        #expect(availability == .hasItemsToRefund)
        #expect(sut.selectableItems.count == 1)
        #expect(sut.selectableItems.first?.isLumpSum == true)
    }

    @MainActor
    @Test func test_prepareRefundReview_with_custom_amount_only_then_returns_lump_sum_total() async throws {
        // Given - one fee of $10, no products
        let customAmount = makePOSOrderCustomAmount(id: 777, name: "Discount Fee", total: 10, totalTax: 0)
        let order = makeOrder(lineItems: [], customAmounts: [customAmount])

        // When
        _ = await sut.startRefundFlow(for: order)
        let reviewData = await prepareReviewData(sut)

        // Then
        #expect(reviewData?.itemsCount == 1)
        #expect(reviewData?.formattedItemsSubtotal == "$10.00")
        #expect(reviewData?.formattedRefundTotal == "$10.00")
    }

    @MainActor
    @Test func test_prepareRefundReview_with_mixed_products_and_custom_amount_then_sums_both() async throws {
        // Given - one product ($10) and one fee ($5)
        let customAmount = makePOSOrderCustomAmount(id: 777, name: "Discount Fee", total: 5, totalTax: 0)
        let order = makeOrder(
            lineItems: [makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")],
            customAmounts: [customAmount]
        )

        // When
        _ = await sut.startRefundFlow(for: order)
        let reviewData = await prepareReviewData(sut)

        // Then
        #expect(reviewData?.itemsCount == 2)
        #expect(reviewData?.formattedItemsSubtotal == "$15.00")
        #expect(reviewData?.formattedRefundTotal == "$15.00")
    }

    @MainActor
    @Test func startRefundFlow_when_multiple_refunds_exist_then_aggregates_refunded_quantities() async throws {
        // Given: Order has 5 units of item, refunded across two separate refunds (2 + 2 = 4)
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [
                POSRefund(items: [POSRefundItem(refundedItemID: 1, quantity: -2, name: "", formattedPrice: "", formattedTotal: "", imageSrc: nil)]),
                POSRefund(items: [POSRefundItem(refundedItemID: 1, quantity: -2, name: "", formattedPrice: "", formattedTotal: "", imageSrc: nil)])
            ],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 5, formattedPrice: "$10.00", formattedTotal: "$50.00")
        ])

        // When
        _ = await sut.startRefundFlow(for: order)

        // Then: Should only show 1 available (5 - 4 refunded)
        #expect(sut.selectableItems.count == 1)
    }

    @MainActor
    @Test func toggleItemSelection_then_toggles_item_at_index() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        _ = await sut.startRefundFlow(for: order)

        // When
        sut.toggleItemSelection(at: 0)
        let isSelectedAfterToggle = sut.selectableItems[0].isSelected

        // Then
        #expect(isSelectedAfterToggle == false)
    }

    @MainActor
    @Test func toggleItemSelection_then_marks_refund_selection_as_modified() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, formattedPrice: "$10.00", formattedTotal: "$10.00")
        ])

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

    @MainActor
    @Test func clearSelection_then_removes_all_items() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        _ = await sut.startRefundFlow(for: order)
        try #require(sut.selectableItems.count == 2)

        // When
        sut.clearSelection()

        // Then
        #expect(sut.selectableItems.isEmpty)
    }

    @MainActor
    @Test func clearSelection_then_resets_modified_refund_selection() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, formattedPrice: "$10.00", formattedTotal: "$10.00")
        ])

        _ = await sut.startRefundFlow(for: order)
        sut.toggleItemSelection(at: 0)
        try #require(sut.hasModifiedSelection == true)

        // When
        sut.clearSelection()

        // Then
        #expect(sut.hasModifiedSelection == false)
    }

    @MainActor
    @Test func toggleAllItemsSelection_when_all_selected_then_deselects_all() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        _ = await sut.startRefundFlow(for: order)

        // When
        sut.toggleAllItemsSelection()

        // Then
        for item in sut.selectableItems {
            #expect(item.isSelected == false)
        }
    }

    @MainActor
    @Test func toggleAllItemsSelection_then_marks_refund_selection_as_modified() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        _ = await sut.startRefundFlow(for: order)
        #expect(sut.hasModifiedSelection == false)

        // When
        sut.toggleAllItemsSelection()

        // Then
        #expect(sut.hasModifiedSelection == true)
    }

    @MainActor
    @Test func toggleAllItemsSelection_when_some_deselected_then_selects_all() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        _ = await sut.startRefundFlow(for: order)
        sut.toggleItemSelection(at: 0) // Deselect first item

        // When
        sut.toggleAllItemsSelection()

        // Then
        for item in sut.selectableItems {
            #expect(item.isSelected == true)
        }
    }

    @MainActor
    @Test func toggleAllItemsSelection_when_none_selected_then_selects_all() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        _ = await sut.startRefundFlow(for: order)
        sut.toggleAllItemsSelection() // Deselect all

        // When
        sut.toggleAllItemsSelection() // Should select all

        // Then
        for item in sut.selectableItems {
            #expect(item.isSelected == true)
        }
    }

    @MainActor
    @Test func reset_then_clears_the_selection() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, formattedPrice: "$10.00", formattedTotal: "$10.00")
        ])

        _ = await sut.startRefundFlow(for: order)
        sut.toggleItemSelection(at: 0)
        try #require(sut.hasModifiedSelection == true)
        try #require(sut.selectableItems.isNotEmpty)

        // When
        sut.reset()

        // Then
        #expect(sut.selectableItems.isEmpty)
        #expect(sut.hasModifiedSelection == false)
    }

    // MARK: - Prepare Refund Review Data Tests

    @MainActor
    @Test func prepareReview_when_no_items_selected_then_returns_nil() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, formattedPrice: "$10.00")
        ])

        // When
        _ = await sut.startRefundFlow(for: order)
        sut.toggleAllItemsSelection() // Deselect all

        // Then
        let reviewData = await prepareReviewData(sut)
        #expect(reviewData == nil)
    }

    @MainActor
    @Test func prepareReview_then_returns_correct_items_count() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 3, price: 10.00, formattedPrice: "$10.00")
        ])

        // When
        _ = await sut.startRefundFlow(for: order)

        // Then
        let reviewData = await prepareReviewData(sut)
        #expect(reviewData?.itemsCount == 3)
    }

    @MainActor
    @Test func prepareReview_then_returns_correct_subtotal() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, formattedPrice: "$10.00"),
            makePOSOrderItem(itemID: 2, quantity: 1, price: 5.50, formattedPrice: "$5.50")
        ])

        // When
        _ = await sut.startRefundFlow(for: order)

        // Then
        // 2 × $10.00 + 1 × $5.50 = $25.50
        let reviewData = await prepareReviewData(sut)
        #expect(reviewData?.formattedItemsSubtotal == "$25.50")
    }

    @MainActor
    @Test func prepareReview_when_full_refund_then_uses_original_tax() async throws {
        // Given - item with quantity 2 and totalTax of $1.50 (for both units)
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, totalTax: 1.50, formattedPrice: "$10.00")
        ])

        // When - all items selected (full refund)
        _ = await sut.startRefundFlow(for: order)

        // Then - should use original totalTax directly ($1.50)
        let reviewData = await prepareReviewData(sut)
        #expect(reviewData?.formattedTax == "$1.50")
    }

    @MainActor
    @Test func prepareReview_when_partial_refund_then_calculates_proportional_tax() async throws {
        // Given - item with quantity 2 and totalTax of $1.50 (for both units)
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, totalTax: 1.50, formattedPrice: "$10.00")
        ])

        // When - only 1 of 2 items selected (partial refund)
        _ = await sut.startRefundFlow(for: order)
        sut.toggleItemSelection(at: 0) // Deselect first item, leaving 1 selected

        // Then - should calculate proportionally: $1.50 / 2 × 1 = $0.75
        let reviewData = await prepareReviewData(sut)
        #expect(reviewData?.formattedTax == "$0.75")
    }

    @MainActor
    @Test func prepareReview_then_returns_correct_total() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, totalTax: 1.00, formattedPrice: "$10.00")
        ])

        // When
        _ = await sut.startRefundFlow(for: order)

        // Then - $10.00 + $1.00 = $11.00
        let reviewData = await prepareReviewData(sut)
        #expect(reviewData?.formattedRefundTotal == "$11.00")
    }

    @MainActor
    @Test func prepareReview_then_returns_via_payment_method_title() async throws {
        // Given
        let order = makeOrder(paymentMethodTitle: "WooCommerce In-Person Payments", lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

        // When
        _ = await sut.startRefundFlow(for: order)

        // Then
        let reviewData = await prepareReviewData(sut)
        #expect(reviewData?.paymentMethodDescription == "via WooCommerce In-Person Payments")
    }

    @MainActor
    @Test func prepareReview_then_refund_reason_is_nil_by_default() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

        // When
        _ = await sut.startRefundFlow(for: order)

        // Then
        let reviewData = await prepareReviewData(sut)
        #expect(reviewData?.refundReason == nil)
    }

    @MainActor
    @Test func requiresCardPresentRefund_when_preparation_requires_card_present_refund_then_returns_true() async throws {
        // Given
        refundSubmissionProcessor.requiresCardPresentRefund = true
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

        // When
        _ = await sut.startRefundFlow(for: order)

        // Then
        #expect(sut.requiresCardPresentRefund == true)
    }

    // MARK: - Currency Formatting Tests

    @MainActor
    @Test func prepareReview_with_EUR_currency_then_formats_with_comma_decimal_separator() async throws {
        // Given - EUR with comma decimal separator and dot thousand separator
        let eurSettings = CurrencySettings(
            currencyCode: .EUR,
            currencyPosition: .rightSpace,
            thousandSeparator: ".",
            decimalSeparator: ",",
            numberOfDecimals: 2
        )
        let controller = makeController(currencySettings: eurSettings)

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, price: 1172.02, totalTax: 234.40, formattedPrice: "1.172,02 €")
        ])

        // When
        _ = await controller.startRefundFlow(for: order)
        let reviewData = await prepareReviewData(controller)

        // Then - 2 × €1,172.02 = €2,344.04, tax = €234.40, total = €2,578.44
        // Note: CurrencyFormatter uses non-breaking space (\u{00A0}) before currency symbol
        #expect(reviewData?.formattedItemsSubtotal == "2.344,04\u{00A0}€")
        #expect(reviewData?.formattedTax == "234,40\u{00A0}€")
        #expect(reviewData?.formattedRefundTotal == "2.578,44\u{00A0}€")
    }

    @MainActor
    @Test func prepareReview_with_JPY_currency_then_formats_without_decimals() async throws {
        // Given - JPY with no decimals
        let jpySettings = CurrencySettings(
            currencyCode: .JPY,
            currencyPosition: .left,
            thousandSeparator: ",",
            decimalSeparator: ".",
            numberOfDecimals: 0
        )
        let controller = makeController(currencySettings: jpySettings)

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 2344, totalTax: 234, formattedPrice: "¥2,344")
        ])

        // When
        _ = await controller.startRefundFlow(for: order)
        let reviewData = await prepareReviewData(controller)

        // Then
        #expect(reviewData?.formattedItemsSubtotal == "¥2,344")
        #expect(reviewData?.formattedTax == "¥234")
        #expect(reviewData?.formattedRefundTotal == "¥2,578")
    }

    @MainActor
    @Test func prepareReview_with_GBP_and_large_values_then_formats_correctly() async throws {
        // Given - GBP with large values
        let gbpSettings = CurrencySettings(
            currencyCode: .GBP,
            currencyPosition: .left,
            thousandSeparator: ",",
            decimalSeparator: ".",
            numberOfDecimals: 2
        )
        let controller = makeController(currencySettings: gbpSettings)

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 12345.67, totalTax: 2469.13, formattedPrice: "£12,345.67")
        ])

        // When
        _ = await controller.startRefundFlow(for: order)
        let reviewData = await prepareReviewData(controller)

        // Then
        #expect(reviewData?.formattedItemsSubtotal == "£12,345.67")
        #expect(reviewData?.formattedTax == "£2,469.13")
        #expect(reviewData?.formattedRefundTotal == "£14,814.80")
    }

    @MainActor
    @Test func prepareReview_with_USD_and_large_value_from_screenshot_then_formats_correctly() async throws {
        // Given - USD with value from screenshot: $2,344.04
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 2344.04, totalTax: 234.40, formattedPrice: "$2,344.04")
        ])

        // When
        _ = await sut.startRefundFlow(for: order)
        let reviewData = await prepareReviewData(sut)

        // Then
        #expect(reviewData?.formattedItemsSubtotal == "$2,344.04")
        #expect(reviewData?.formattedTax == "$234.40")
        #expect(reviewData?.formattedRefundTotal == "$2,578.44")
    }

    // MARK: - Refund Review Preparation State

    @MainActor
    @Test func prepareReview_when_processor_throws_then_state_is_previewError_and_retry_recovers() async throws {
        // Given
        let order = makeOrder(lineItems: [makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")])
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

    @MainActor
    @Test func prepareReview_when_processor_throws_typed_rejection_then_state_carries_its_message() async throws {
        // Given the preview was rejected with an actionable code (e.g. the order changed since loading)
        let order = makeOrder(lineItems: [makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")])
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

    @MainActor
    @Test func prepareReview_when_order_is_not_refundable_then_flow_ends_on_the_terminal_state() async throws {
        // Given the store reports the order as having nothing refundable left
        let order = makeOrder(lineItems: [makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")])
        _ = await sut.startRefundFlow(for: order)
        refundSubmissionProcessor.prepareReviewDataErrorToThrow = RefundAPIError.orderNotRefundable

        // When
        let result = await awaitReviewPreparation(sut)

        // Then there is no selection to recover to, so the caller is told to end the flow
        #expect(result == .nothingToRefund)
        #expect(sut.reviewPreparationState == .idle)
    }

    @MainActor
    @Test func refreshRefundableItems_when_the_reloaded_list_is_unchanged_then_clears_the_selection() async throws {
        // Given two refundable units, with only the first one selected
        let order = makeOrder(lineItems: [makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, formattedPrice: "$10.00")])
        _ = await sut.startRefundFlow(for: order)
        sut.toggleItemSelection(at: 1)

        // When the reload returns the same list, as an order-level rejection does
        let result = await sut.refreshRefundableItems()

        // Then nothing is selected
        #expect(result == .hasItemsToRefund)
        #expect(sut.selectableItems.count == 2)
        #expect(sut.selectableItems.allSatisfy { !$0.isSelected })
    }

    @MainActor
    @Test func refreshRefundableItems_when_a_unit_was_refunded_elsewhere_then_clears_the_selection() async throws {
        // Given three refundable units, all selected
        let order = makeOrder(lineItems: [makePOSOrderItem(itemID: 1, quantity: 3, price: 10.00, formattedPrice: "$10.00")])
        _ = await sut.startRefundFlow(for: order)

        // When another register refunds one unit and the cashier reloads
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [POSRefund(items: [POSRefundItem(refundedItemID: 1,
                                                     quantity: -1,
                                                     name: "",
                                                     formattedPrice: "",
                                                     formattedTotal: "",
                                                     imageSrc: nil)])],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )
        let result = await sut.refreshRefundableItems()

        // Then the two remaining units are listed and none of them is selected
        #expect(result == .hasItemsToRefund)
        #expect(sut.selectableItems.count == 2)
        #expect(sut.selectableItems.allSatisfy { !$0.isSelected })
    }

    @MainActor
    @Test func refreshRefundableItems_then_hasModifiedRefundSelection_is_false_until_the_next_toggle() async throws {
        // Given a reloaded list with nothing selected
        let order = makeOrder(lineItems: [makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, formattedPrice: "$10.00")])
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

    @MainActor
    @Test func refreshRefundableItems_when_a_preview_error_is_shown_then_it_is_cleared() async throws {
        // Given a rejected preview
        let order = makeOrder(lineItems: [makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")])
        _ = await sut.startRefundFlow(for: order)
        refundSubmissionProcessor.prepareReviewDataErrorToThrow = RefundAPIError.lineItemAlreadyRefunded
        _ = await awaitReviewPreparation(sut)

        // When the cashier reloads the refundable items
        refundSubmissionProcessor.prepareReviewDataErrorToThrow = nil
        _ = await sut.refreshRefundableItems()

        // Then the selection step is back to a clean state
        #expect(sut.reviewPreparationState == .idle)
    }

    @MainActor
    @Test func prepareReview_when_selection_changes_mid_flight_then_result_is_dropped() async throws {
        // Given an order with two refundable units so a toggle is possible mid-flight
        let order = makeOrder(lineItems: [makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, formattedPrice: "$10.00")])
        _ = await sut.startRefundFlow(for: order)
        refundSubmissionProcessor.onPrepareReviewDataCalled = { [weak sut] in
            sut?.toggleItemSelection(at: 0)
        }

        // When
        let result = await awaitReviewPreparation(sut)

        // Then the toggle superseded the preparation, and the stale result never advanced the state
        #expect(result == .superseded)
        await Task.yield()
        await Task.yield()
        #expect(sut.reviewPreparationState == .idle)
    }

    @MainActor
    @Test func prepareReview_when_the_flow_is_reset_mid_flight_then_preparation_is_cancelled() async throws {
        // Given
        let order = makeOrder(lineItems: [makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")])
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

    @MainActor
    @Test func prepareReview_when_no_preparation_loaded_then_returns_preparationError() async throws {
        // Given no selected order / no started refund flow

        // When
        let result = await sut.prepareReview()

        // Then
        #expect(result == .preparationError)
        #expect(sut.reviewPreparationState == .idle)
    }

    @MainActor
    @Test func resetReviewPreparation_returns_state_to_idle() async throws {
        // Given a completed preparation
        let order = makeOrder(lineItems: [makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")])
        _ = await sut.startRefundFlow(for: order)
        _ = await awaitReviewPreparation(sut)

        // When
        sut.resetReviewPreparation()

        // Then
        #expect(sut.reviewPreparationState == .idle)
    }

    // MARK: - Process Refund Tests

    @MainActor
    @Test func processRefund_then_submits_refund_with_correct_order_id() async throws {
        // Given
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(id: 123, lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

        _ = await sut.startRefundFlow(for: order)

        // When
        _ = try await sut.processRefund(reason: .none)

        // Then
        #expect(refundSubmissionProcessor.submitRefundCalled == true)
        #expect(refundSubmissionProcessor.spySubmitRefundOrderID == 123)
    }

    @MainActor
    @Test func processRefund_then_submits_refund_with_selected_items() async throws {
        // Given
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, formattedPrice: "$10.00"),
            makePOSOrderItem(itemID: 2, quantity: 1, price: 5.00, formattedPrice: "$5.00")
        ])

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

    @MainActor
    @Test func processRefund_then_submits_refund_with_reason() async throws {
        // Given
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

        _ = await sut.startRefundFlow(for: order)

        // When
        _ = try await sut.processRefund(reason: "Customer changed their mind")

        // Then
        #expect(refundSubmissionProcessor.spySubmitRefundReason == "Customer changed their mind")
    }

    @MainActor
    @Test func processRefund_when_successful_then_clears_selection() async throws {
        // Given
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, formattedPrice: "$10.00")
        ])

        _ = await sut.startRefundFlow(for: order)
        try #require(sut.selectableItems.count == 2)

        // When
        _ = try await sut.processRefund(reason: .none)

        // Then
        #expect(sut.selectableItems.isEmpty)
    }

    @MainActor
    @Test func processRefund_when_submission_throws_then_propagates_error() async throws {
        // Given
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

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

    @MainActor
    @Test func processRefund_when_no_refund_flow_was_started_then_throws_missingSelectedOrder() async throws {
        await #expect(performing: {
            _ = try await sut.processRefund(reason: .none)
        }, throws: { error in
            (error as? POSRefundProcessingError) == .missingSelectedOrder
        })
    }

    @MainActor
    @Test func processRefund_when_refund_is_not_prepared_then_throws_missingRefundPreparation() async throws {
        // Given the flow was started for an order the store failed to prepare
        refundSubmissionProcessor.prepareRefundErrorToThrow = TestError.prepareRefundFailed
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])
        _ = await sut.startRefundFlow(for: order)

        // When / Then
        await #expect(performing: {
            _ = try await sut.processRefund(reason: .none)
        }, throws: { error in
            (error as? POSRefundProcessingError) == .missingRefundPreparation
        })
    }

    @MainActor
    @Test func processRefund_when_no_items_are_selected_then_throws_emptySelection() async throws {
        // Given
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])
        _ = await sut.startRefundFlow(for: order)
        sut.toggleAllItemsSelection()

        // When / Then
        await #expect(performing: {
            _ = try await sut.processRefund(reason: .none)
        }, throws: { error in
            (error as? POSRefundProcessingError) == .emptySelection
        })
    }

    @MainActor
    @Test func processRefund_when_refund_is_already_in_progress_then_throws_refundAlreadyInProgress() async throws {
        // Given
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])
        _ = await sut.startRefundFlow(for: order)
        refundSubmissionProcessor.shouldSuspendSubmitRefund = true

        var firstRefundTask: Task<Void, Error>?
        await fireOnce { fire in
            refundSubmissionProcessor.onSubmitRefundStarted = {
                fire()
            }
            firstRefundTask = Task { @MainActor in
                _ = try await sut.processRefund(reason: .none)
            }
        }

        // When / Then
        await #expect(performing: {
            _ = try await sut.processRefund(reason: .none)
        }, throws: { error in
            (error as? POSRefundProcessingError) == .refundAlreadyInProgress
        })

        refundSubmissionProcessor.resumeSubmitRefund()
        try await firstRefundTask?.value
    }

    @MainActor
    @Test func processRefund_then_converts_items_with_correct_properties() async throws {
        // Given
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 42, quantity: 3, price: 15.50, totalTax: 1.55, formattedPrice: "$15.50")
        ])

        _ = await sut.startRefundFlow(for: order)

        // When
        _ = try await sut.processRefund(reason: .none)

        // Then
        let items = try #require(refundSubmissionProcessor.spySubmitRefundItems)
        #expect(items.count == 3)

        let firstItem = items[0]
        #expect(firstItem.itemID == 42)
        #expect(firstItem.lineItemTotal == 46.50)
        #expect(firstItem.totalTax == 1.55)
        #expect(firstItem.originalQuantity == 3)
    }

    @MainActor
    @Test func processRefund_when_supportsAutomaticRefund_is_true_then_submits_refund_with_automatic_refund_true() async throws {
        // Given
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

        _ = await sut.startRefundFlow(for: order)

        // When
        _ = try await sut.processRefund(reason: .none)

        // Then
        #expect(refundSubmissionProcessor.spySubmitRefundIsAutomaticRefund == true)
    }

    @MainActor
    @Test func processRefund_when_supportsAutomaticRefund_is_false_then_submits_refund_with_automatic_refund_false() async throws {
        // Given
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: false
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

        _ = await sut.startRefundFlow(for: order)

        // When
        _ = try await sut.processRefund(reason: .none)

        // Then
        #expect(refundSubmissionProcessor.spySubmitRefundIsAutomaticRefund == false)
    }
}

private extension POSRefundControllerTests {
    /// Runs review preparation and returns its outcome.
    @MainActor
    func awaitReviewPreparation(_ controller: POSRefundController) async -> POSRefundReviewPreparationResult {
        await controller.prepareReview()
    }

    /// Runs async review preparation and returns the review data, or `nil` when preparation failed.
    @MainActor
    func prepareReviewData(_ controller: POSRefundController) async -> POSRefundReviewData? {
        guard case .ready(let reviewData) = await awaitReviewPreparation(controller) else {
            return nil
        }
        return reviewData
    }

    func makeController(currencySettings: CurrencySettings) -> POSRefundController {
        let formatter = CurrencyFormatter(currencySettings: currencySettings)
        return POSRefundController(
            refundSubmissionProcessor: MockPOSRefundSubmissionProcessor(refundsService: refundsService,
                                                                        currencyFormatter: formatter)
        )
    }
}

private final class MockPOSRefundSubmissionProcessor: POSRefundSubmissionProcessing {
    let stateModel = POSRefundSubmissionModel()

    nonisolated(unsafe) private let refundsService: MockPOSRefundsService
    nonisolated(unsafe) private let currencyFormatter: CurrencyFormatter
    private var refundResultsByOrderID: [Int64: POSRefundsResult] = [:]
    var requiresCardPresentRefund = false
    var shouldSuspendSubmitRefund = false
    var onSubmitRefundStarted: (() -> Void)?
    private var submitRefundContinuation: CheckedContinuation<Void, Never>?

    private(set) var submitRefundCalled = false
    private(set) var spySubmitRefundOrderID: Int64?
    private(set) var spySubmitRefundItems: [POSRefundSelectableItem]?
    private(set) var spySubmitRefundReason: String?
    private(set) var spySubmitRefundIsAutomaticRefund: Bool?
    var submitRefundErrorToThrow: Error?

    nonisolated init(refundsService: MockPOSRefundsService,
                     currencyFormatter: CurrencyFormatter) {
        self.refundsService = refundsService
        self.currencyFormatter = currencyFormatter
    }

    private(set) var preloadedOrderIDs: [Int64] = []
    var prepareRefundErrorToThrow: Error?

    func preloadRefund(for order: POSOrder) async {
        preloadedOrderIDs.append(order.id)
    }

    func prepareRefund(for order: POSOrder) async throws -> POSRefundPreparation {
        if let prepareRefundErrorToThrow {
            throw prepareRefundErrorToThrow
        }
        let refundsResult = try await refundsService.providePointOfSaleRefunds(for: order)
        refundResultsByOrderID[order.id] = refundsResult

        let refundedQuantitiesByItemID = refundsResult.refunds.flatMap(\.items).refundedQuantitiesByItemID()
        let productSelectables = order.lineItems.flatMap { item -> [POSRefundSelectableItem] in
            let originalQuantity = NSDecimalNumber(decimal: item.quantity).intValue
            let refundedQuantity = refundedQuantitiesByItemID[item.itemID] ?? 0
            let availableQuantity = originalQuantity - refundedQuantity
            guard availableQuantity > 0 else { return [] }

            return (0..<availableQuantity).map { index in
                POSRefundSelectableItem(from: item, isSelected: true, index: index)
            }
        }

        let alreadyRefundedItemIDs = Set(refundsResult.refunds.flatMap(\.items).compactMap(\.refundedItemID))
        let feeSelectables = order.customAmounts
            .filter { !alreadyRefundedItemIDs.contains($0.id) }
            .map { POSRefundSelectableItem(from: $0, isSelected: true) }

        return POSRefundPreparation(
            orderID: order.id,
            selectableItems: productSelectables + feeSelectables,
            paymentMethodDescription: String(format: "via %1$@", order.paymentMethodTitle),
            customerEmail: order.customerEmail,
            requiresCardPresentRefund: requiresCardPresentRefund
        )
    }

    var prepareReviewDataErrorToThrow: Error?
    var onPrepareReviewDataCalled: (@MainActor () async -> Void)?

    func prepareReviewData(for order: POSOrder,
                           preparation: POSRefundPreparation,
                           selectedItems: [POSRefundSelectableItem],
                           reason: String?) async throws -> POSRefundReviewData {
        await onPrepareReviewDataCalled?()
        if let error = prepareReviewDataErrorToThrow {
            throw error
        }

        let amounts = reviewAmounts(for: selectedItems)
        return POSRefundReviewData(
            itemsCount: selectedItems.count,
            formattedItemsSubtotal: currencyFormatter.formatAmount(amounts.subtotal) ?? "",
            formattedTax: currencyFormatter.formatAmount(amounts.tax) ?? "",
            formattedRefundTotal: currencyFormatter.formatAmount(amounts.subtotal + amounts.tax) ?? "",
            paymentMethodDescription: preparation.paymentMethodDescription,
            customerEmail: preparation.customerEmail,
            refundReason: reason,
            isFullRefund: selectedItems.count == preparation.selectableItems.count,
            calculationFlow: .local
        )
    }

    func submitRefund(for order: POSOrder,
                      preparation: POSRefundPreparation,
                      selectedItems: [POSRefundSelectableItem],
                      reason: String?) async throws {
        onSubmitRefundStarted?()
        if shouldSuspendSubmitRefund {
            await withCheckedContinuation { continuation in
                submitRefundContinuation = continuation
            }
        }

        submitRefundCalled = true
        spySubmitRefundOrderID = order.id
        spySubmitRefundItems = selectedItems
        spySubmitRefundReason = reason
        spySubmitRefundIsAutomaticRefund = refundResultsByOrderID[preparation.orderID]?.supportsAutomaticRefund ?? true

        if let error = submitRefundErrorToThrow {
            throw error
        }

        stateModel.state = .completed
    }

    private func reviewAmounts(for items: [POSRefundSelectableItem]) -> (subtotal: Decimal, tax: Decimal) {
        let groupedItems = Dictionary(grouping: items, by: \.itemID)
        return groupedItems.values.reduce((subtotal: Decimal.zero, tax: Decimal.zero)) { result, items in
            let subtotal = calculateAmount(for: items, keyPath: \.lineItemTotal)
            let tax = calculateAmount(for: items, keyPath: \.totalTax)
            return (result.subtotal + subtotal, result.tax + tax)
        }
    }

    private func calculateAmount(for items: [POSRefundSelectableItem], keyPath: KeyPath<POSRefundSelectableItem, Decimal>) -> Decimal {
        guard let firstItem = items.first, firstItem.originalQuantity > 0 else {
            return .zero
        }

        if firstItem.isLumpSum || Decimal(items.count) == firstItem.originalQuantity {
            return firstItem[keyPath: keyPath]
        }

        return (firstItem[keyPath: keyPath] / firstItem.originalQuantity) * Decimal(items.count)
    }

    func resumeSubmitRefund() {
        shouldSuspendSubmitRefund = false
        submitRefundContinuation?.resume()
        submitRefundContinuation = nil
    }
}
