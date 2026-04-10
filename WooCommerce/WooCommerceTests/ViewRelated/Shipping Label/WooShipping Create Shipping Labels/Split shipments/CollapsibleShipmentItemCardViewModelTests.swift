import XCTest
@testable import WooCommerce
import WooFoundation
import Yosemite

final class CollapsibleShipmentItemCardViewModelTests: XCTestCase {

    // MARK: - observeSelection Tests

    func test_observeSelection_when_main_item_selected_then_all_children_are_selected() {
        // Given
        let packageItem = samplePackageItem(quantity: 3)
        let viewModel = CollapsibleShipmentItemCardViewModel(item: packageItem, currency: "USD")

        var selectionChangeCallCount = 0
        viewModel.onSelectionChange = {
            selectionChangeCallCount += 1
        }

        // When
        viewModel.mainItemRow.handleTap() // Select main item

        // Then
        XCTAssertTrue(viewModel.mainItemRow.selected)
        XCTAssertTrue(viewModel.childItemRows.allSatisfy { $0.selected })
        XCTAssertEqual(selectionChangeCallCount, 1)
    }

    func test_observeSelection_when_main_item_deselected_then_all_children_are_deselected() {
        // Given
        let packageItem = samplePackageItem(quantity: 3)
        let viewModel = CollapsibleShipmentItemCardViewModel(item: packageItem, currency: "USD")

        // First select the main item
        viewModel.mainItemRow.handleTap()

        var selectionChangeCallCount = 0
        viewModel.onSelectionChange = {
            selectionChangeCallCount += 1
        }

        // When
        viewModel.mainItemRow.handleTap() // Deselect main item

        // Then
        XCTAssertFalse(viewModel.mainItemRow.selected)
        XCTAssertTrue(viewModel.childItemRows.allSatisfy { !$0.selected })
        XCTAssertEqual(selectionChangeCallCount, 1)
    }

    func test_observeSelection_when_all_children_selected_then_main_item_is_selected() {
        // Given
        let packageItem = samplePackageItem(quantity: 3)
        let viewModel = CollapsibleShipmentItemCardViewModel(item: packageItem, currency: "USD")

        var selectionChangeCallCount = 0
        viewModel.onSelectionChange = {
            selectionChangeCallCount += 1
        }

        // When - Select all child items one by one
        viewModel.childItemRows[0].handleTap()
        viewModel.childItemRows[1].handleTap()
        viewModel.childItemRows[2].handleTap()

        // Then
        XCTAssertTrue(viewModel.mainItemRow.selected)
        XCTAssertTrue(viewModel.childItemRows.allSatisfy { $0.selected })
        XCTAssertEqual(selectionChangeCallCount, 3)
    }

    func test_observeSelection_when_some_children_selected_then_main_item_is_not_selected() {
        // Given
        let packageItem = samplePackageItem(quantity: 3)
        let viewModel = CollapsibleShipmentItemCardViewModel(item: packageItem, currency: "USD")

        var selectionChangeCallCount = 0
        viewModel.onSelectionChange = {
            selectionChangeCallCount += 1
        }

        // When - Select only some child items
        viewModel.childItemRows[0].handleTap()
        viewModel.childItemRows[1].handleTap()
        // Note: childItemRows[2] is not selected

        // Then
        XCTAssertFalse(viewModel.mainItemRow.selected)
        XCTAssertTrue(viewModel.childItemRows[0].selected)
        XCTAssertTrue(viewModel.childItemRows[1].selected)
        XCTAssertFalse(viewModel.childItemRows[2].selected)
        XCTAssertEqual(selectionChangeCallCount, 2)
    }

    func test_observeSelection_when_all_children_selected_then_one_deselected_then_main_item_is_deselected() {
        // Given
        let packageItem = samplePackageItem(quantity: 3)
        let viewModel = CollapsibleShipmentItemCardViewModel(item: packageItem, currency: "USD")

        // First select all children
        viewModel.childItemRows.forEach { $0.handleTap() }

        // Verify all are selected initially
        XCTAssertTrue(viewModel.mainItemRow.selected)
        XCTAssertTrue(viewModel.childItemRows.allSatisfy { $0.selected })

        var selectionChangeCallCount = 0
        viewModel.onSelectionChange = {
            selectionChangeCallCount += 1
        }

        // When - Deselect one child item
        viewModel.childItemRows[1].handleTap()

        // Then
        XCTAssertFalse(viewModel.mainItemRow.selected)
        XCTAssertTrue(viewModel.childItemRows[0].selected)
        XCTAssertFalse(viewModel.childItemRows[1].selected)
        XCTAssertTrue(viewModel.childItemRows[2].selected)
        XCTAssertEqual(selectionChangeCallCount, 1)
    }

    func test_observeSelection_with_single_quantity_item_has_no_children() {
        // Given
        let packageItem = samplePackageItem(quantity: 1)
        let viewModel = CollapsibleShipmentItemCardViewModel(item: packageItem, currency: "USD")

        // Then
        XCTAssertTrue(viewModel.childItemRows.isEmpty)
        XCTAssertFalse(viewModel.mainItemRow.selected)
    }

    // MARK: - numberOfSelectedItems Tests

    func test_numberOfSelectedItems_with_single_quantity_item() {
        // Given
        let packageItem = samplePackageItem(quantity: 1)
        let viewModel = CollapsibleShipmentItemCardViewModel(item: packageItem, currency: "USD")

        // When not selected
        XCTAssertEqual(viewModel.numberOfSelectedItems, 0)

        // When selected
        viewModel.mainItemRow.handleTap()
        XCTAssertEqual(viewModel.numberOfSelectedItems, 1)
    }

    func test_numberOfSelectedItems_with_multiple_quantity_item() {
        // Given
        let packageItem = samplePackageItem(quantity: 3)
        let viewModel = CollapsibleShipmentItemCardViewModel(item: packageItem, currency: "USD")

        // When no children selected
        XCTAssertEqual(viewModel.numberOfSelectedItems, 0)

        // When some children selected
        viewModel.childItemRows[0].handleTap()
        viewModel.childItemRows[1].handleTap()
        XCTAssertEqual(viewModel.numberOfSelectedItems, 2)

        // When all children selected
        viewModel.childItemRows[2].handleTap()
        XCTAssertEqual(viewModel.numberOfSelectedItems, 3)
    }

    // MARK: - selectAll Tests

    func test_selectAll_selects_main_and_all_children() {
        // Given
        let packageItem = samplePackageItem(quantity: 3)
        let viewModel = CollapsibleShipmentItemCardViewModel(item: packageItem, currency: "USD")

        var selectionChangeCallCount = 0
        viewModel.onSelectionChange = {
            selectionChangeCallCount += 1
        }

        // When
        viewModel.selectAll()

        // Then
        XCTAssertTrue(viewModel.mainItemRow.selected)
        XCTAssertTrue(viewModel.childItemRows.allSatisfy { $0.selected })
        XCTAssertEqual(selectionChangeCallCount, 1)
    }

    func test_selectAll_with_single_quantity_item() {
        // Given
        let packageItem = samplePackageItem(quantity: 1)
        let viewModel = CollapsibleShipmentItemCardViewModel(item: packageItem, currency: "USD")

        var selectionChangeCallCount = 0
        viewModel.onSelectionChange = {
            selectionChangeCallCount += 1
        }

        // When
        viewModel.selectAll()

        // Then
        XCTAssertTrue(viewModel.mainItemRow.selected)
        XCTAssertTrue(viewModel.childItemRows.isEmpty)
        XCTAssertEqual(selectionChangeCallCount, 1)
    }
}

// MARK: - Helper Methods

private extension CollapsibleShipmentItemCardViewModelTests {
    func samplePackageItem(quantity: Decimal) -> ShippingLabelPackageItem {
        ShippingLabelPackageItem(
            productOrVariationID: 123,
            orderItemID: 456,
            name: "Test Item",
            weight: 1.5,
            quantity: quantity,
            value: 10.0,
            dimensions: ProductDimensions(length: "10", width: "10", height: "10"),
            attributes: [],
            imageURL: nil
        )
    }
}
