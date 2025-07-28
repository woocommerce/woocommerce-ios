import XCTest
@testable import WooCommerce
import WooFoundation
import Yosemite
import struct Networking.WooShippingLabelData
import struct Networking.ShippingLabel

final class WooShippingSplitShipmentsViewModelTests: XCTestCase {

    private var currencySettings: CurrencySettings!
    private var shippingSettingsService: MockShippingSettingsService!

    let sampleOrder = Order.fake().copy(currency: "INR")

    override func setUp() {
        currencySettings = CurrencySettings()
        shippingSettingsService = MockShippingSettingsService(dimensionUnit: "cm",
                                                              weightUnit: "kg")
    }

    func test_inits_with_expected_values() throws {
        // Given
        let items = [sampleItem(id: 1, weight: 4, value: 10, quantity: 1),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]

        // When
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // Then
        assertEqual("2 items", viewModel.itemsCountLabel)
        assertEqual("₹12.50", viewModel.itemsPriceLabel)
        assertEqual("7 kg • ₹12.50", viewModel.itemsDetailLabel)
    }

    func test_total_items_count_label_handles_single_item() {
        // Given
        let items = [sampleItem(id: 1, weight: 1, value: 1, quantity: 1)]

        // When
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)
        // Then
        assertEqual("1 item", viewModel.itemsCountLabel)
    }

    func test_total_items_count_label_handles_items_with_quantity_greater_than_one() {
        // Given
        let items = [sampleItem(id: 1, weight: 1, value: 1, quantity: 1),
                     sampleItem(id: 2, weight: 1, value: 1, quantity: 2)]

        // When
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)
        // Then
        assertEqual("3 items", viewModel.itemsCountLabel)
    }

    func test_total_items_detail_label_handles_items_with_quantity_greater_than_one() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]

        // When
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // Then
        assertEqual("13 kg • ₹22.50", viewModel.itemsDetailLabel)
    }

    func test_shipments_is_correct_initially_if_config_is_empty() throws {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]

        // When
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // Then
        XCTAssertEqual(viewModel.shipments.count, 1)
        let shipment = try XCTUnwrap(viewModel.shipments.first)
        XCTAssertEqual(shipment.contents.count, items.count)
    }

    func test_shipments_is_correct_initially_if_config_is_not_empty() throws {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]

        // When
        let label = ShippingLabel.fake().copy(shipmentID: "1")
        let refundedLabel = ShippingLabel.fake().copy(shipmentID: "0", refund: .fake())
        let remoteShipments = [
            WooShippingShipment.fake().copy(index: "0", items: [.init(id: 1, subItems: ["sub-1", "sub-2"])], shippingLabel: refundedLabel),
            WooShippingShipment.fake().copy(index: "1", items: [.init(id: 2, subItems: [])], shippingLabel: label)
        ]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: remoteShipments,
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // Then
        XCTAssertEqual(viewModel.shipments.count, 2)
        XCTAssertEqual(viewModel.shipments[0].contents.count, 1)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.orderItemID, items[0].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.quantity, 2)
        XCTAssertFalse(viewModel.shipments[0].isPurchased)

        XCTAssertEqual(viewModel.shipments[1].contents.count, 1)
        XCTAssertEqual(viewModel.shipments[1].contents[0].packageItem.orderItemID, items[1].orderItemID)
        XCTAssertEqual(viewModel.shipments[1].contents[0].packageItem.quantity, 1)
        XCTAssertTrue(viewModel.shipments[1].isPurchased)
    }

    // MARK: - `moveToNoticeViewModel`

    func test_moveToNoticeViewModel_is_nil_initially() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]

        // When
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // Then
        XCTAssertNil(viewModel.moveToNoticeViewModel)
    }

    func test_moveToNoticeViewModel_is_nil_when_there_exists_one_shipment_and_all_items_are_selected() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]

        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // When
        viewModel.selectAll()

        // Then
        XCTAssertNil(viewModel.moveToNoticeViewModel)
    }

    func test_moveToNoticeViewModel_is_correct_when_there_exists_one_shipment_and_not_all_items_are_selected() throws {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]

        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // When
        viewModel.shipments.first?.contents.first?.childItemRows.first?.handleTap()

        // Then
        let moveToNoticeViewModel = try XCTUnwrap(viewModel.moveToNoticeViewModel)
        XCTAssertEqual(moveToNoticeViewModel.allItemsSelected, false)
        XCTAssertEqual(moveToNoticeViewModel.selectedItemsCount, 1)
        XCTAssertEqual(moveToNoticeViewModel.existingShipmentsIndexesToMove, [])
    }

    func test_moveToNoticeViewModel_is_correct_when_there_exists_more_than_one_shipment_and_not_all_items_are_selected() throws {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1),
                     sampleItem(id: 3, weight: 4, value: 5, quantity: 3)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // When
        viewModel.shipments.first?.contents.first?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)
        viewModel.shipments.first?.contents.last?.mainItemRow.handleTap()

        // Then
        let moveToNoticeViewModel = try XCTUnwrap(viewModel.moveToNoticeViewModel)
        XCTAssertEqual(moveToNoticeViewModel.allItemsSelected, false)
        XCTAssertEqual(moveToNoticeViewModel.selectedItemsCount, 3)
        XCTAssertEqual(moveToNoticeViewModel.existingShipmentsIndexesToMove, [1])
    }

    func test_moveToNoticeViewModel_is_correct_when_there_exists_more_than_one_shipment_and_all_items_are_selected() throws {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1),
                     sampleItem(id: 3, weight: 4, value: 5, quantity: 3)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // When
        viewModel.shipments.first?.contents.first?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)
        viewModel.selectAll()

        // Then
        let moveToNoticeViewModel = try XCTUnwrap(viewModel.moveToNoticeViewModel)
        XCTAssertEqual(moveToNoticeViewModel.allItemsSelected, true)
        XCTAssertEqual(moveToNoticeViewModel.selectedItemsCount, 5)
        XCTAssertEqual(moveToNoticeViewModel.existingShipmentsIndexesToMove, [1])
    }

    func test_moveToNoticeViewModel_is_nil_when_there_exist_no_other_unfulfilled_shipments_and_all_items_are_selected() throws {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]

        let label = ShippingLabel.fake().copy(shipmentID: "1")
        let remoteShipments = [
            WooShippingShipment.fake().copy(index: "0", items: [.init(id: 1, subItems: ["sub-1", "sub-2"])]),
            WooShippingShipment.fake().copy(index: "1", items: [.init(id: 2, subItems: [])], shippingLabel: label)
        ]

        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: remoteShipments,
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // When
        viewModel.shipments.first?.contents.first?.childItemRows.first?.handleTap()

        // Then
        let moveToNoticeViewModel = try XCTUnwrap(viewModel.moveToNoticeViewModel)
        XCTAssertEqual(moveToNoticeViewModel.allItemsSelected, false)
        XCTAssertEqual(moveToNoticeViewModel.selectedItemsCount, 1)
        XCTAssertEqual(moveToNoticeViewModel.existingShipmentsIndexesToMove, [])

        // When
        viewModel.selectAll()

        // Then
        XCTAssertNil(viewModel.moveToNoticeViewModel)
    }

    // MARK: - `moveSelectedItems`

    func test_moveSelectedItems_to_new_shipments_works_correctly_when_moving_a_subset_of_items() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // When
        viewModel.shipments.first?.contents.first?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)

        // Then
        XCTAssertEqual(viewModel.shipments.count, 2)

        XCTAssertEqual(viewModel.shipments[0].index, 0)
        XCTAssertEqual(viewModel.shipments[0].contents.count, 2)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.orderItemID, items[0].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.quantity, 1)
        XCTAssertEqual(viewModel.shipments[0].contents[1].packageItem.orderItemID, items[1].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[1].packageItem.quantity, 1)

        XCTAssertEqual(viewModel.shipments[1].index, 1)
        XCTAssertEqual(viewModel.shipments[1].contents.count, 1)
        XCTAssertEqual(viewModel.shipments[1].contents[0].packageItem.orderItemID, items[0].orderItemID)
        XCTAssertEqual(viewModel.shipments[1].contents[0].packageItem.quantity, 1)
    }

    func test_moveSelectedItems_to_new_shipments_works_correctly_when_moving_whole_item() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // When
        viewModel.shipments.first?.contents.first?.mainItemRow.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)

        // Then
        XCTAssertEqual(viewModel.shipments.count, 2)

        XCTAssertEqual(viewModel.shipments[0].index, 0)
        XCTAssertEqual(viewModel.shipments[0].contents.count, 1)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.orderItemID, items[1].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.quantity, 1)

        XCTAssertEqual(viewModel.shipments[1].index, 1)
        XCTAssertEqual(viewModel.shipments[1].contents.count, 1)
        XCTAssertEqual(viewModel.shipments[1].contents[0].packageItem.orderItemID, items[0].orderItemID)
        XCTAssertEqual(viewModel.shipments[1].contents[0].packageItem.quantity, 2)
    }

    func test_moveSelectedItems_to_existing_shipments_works_correctly() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1),
                     sampleItem(id: 3, weight: 4, value: 5, quantity: 3)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // When
        viewModel.shipments.first?.contents.first?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)
        viewModel.shipments.first?.contents.last?.mainItemRow.handleTap()
        viewModel.moveSelectedItems(to: .existingShipment(index: 1))

        // Then
        XCTAssertEqual(viewModel.shipments.count, 2)

        XCTAssertEqual(viewModel.shipments[0].index, 0)
        XCTAssertEqual(viewModel.shipments[0].contents.count, 2)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.orderItemID, items[0].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.quantity, 1)
        XCTAssertEqual(viewModel.shipments[0].contents[1].packageItem.orderItemID, items[1].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[1].packageItem.quantity, 1)

        XCTAssertEqual(viewModel.shipments[1].index, 1)
        XCTAssertEqual(viewModel.shipments[1].contents.count, 2)
        XCTAssertEqual(viewModel.shipments[1].contents[0].packageItem.orderItemID, items[0].orderItemID)
        XCTAssertEqual(viewModel.shipments[1].contents[0].packageItem.quantity, 1)
        XCTAssertEqual(viewModel.shipments[1].contents[1].packageItem.orderItemID, items[2].orderItemID)
        XCTAssertEqual(viewModel.shipments[1].contents[1].packageItem.quantity, 3)
    }

    func test_moveSelectedItems_to_existing_shipments_merges_the_same_items() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1),
                     sampleItem(id: 3, weight: 4, value: 5, quantity: 3)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // When
        viewModel.shipments.first?.contents.last?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)
        viewModel.shipments.first?.contents.last?.childItemRows.last?.handleTap()
        viewModel.moveSelectedItems(to: .existingShipment(index: 1))

        // Then
        XCTAssertEqual(viewModel.shipments.count, 2)

        XCTAssertEqual(viewModel.shipments[0].index, 0)
        XCTAssertEqual(viewModel.shipments[0].contents.count, 3)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.orderItemID, items[0].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.quantity, 2)
        XCTAssertEqual(viewModel.shipments[0].contents[1].packageItem.orderItemID, items[1].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[1].packageItem.quantity, 1)
        XCTAssertEqual(viewModel.shipments[0].contents[2].packageItem.orderItemID, items[2].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[2].packageItem.quantity, 1)

        XCTAssertEqual(viewModel.shipments[1].index, 1)
        XCTAssertEqual(viewModel.shipments[1].contents.count, 1)
        XCTAssertEqual(viewModel.shipments[1].contents[0].packageItem.orderItemID, items[2].orderItemID)
        XCTAssertEqual(viewModel.shipments[1].contents[0].packageItem.quantity, 2)
    }

    func test_moveSelectedItems_removes_empty_shipment_after_moving() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // When
        viewModel.shipments.first?.contents.last?.mainItemRow.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)
        viewModel.shipments.first?.contents.first?.mainItemRow.handleTap()
        viewModel.moveSelectedItems(to: .existingShipment(index: 1))

        // Then
        XCTAssertEqual(viewModel.shipments.count, 1)

        XCTAssertEqual(viewModel.shipments[0].index, 0)
        XCTAssertEqual(viewModel.shipments[0].contents.count, 2)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.orderItemID, items[1].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.quantity, 1)
        XCTAssertEqual(viewModel.shipments[0].contents[1].packageItem.orderItemID, items[0].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[1].packageItem.quantity, 2)
    }

    func test_moveSelectedItems_to_new_shipments_updates_section_headers_for_current_shipment() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // When
        viewModel.shipments.first?.contents.first?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)

        // Then
        assertEqual("2 items", viewModel.itemsCountLabel)
        assertEqual("₹12.50", viewModel.itemsPriceLabel)
        assertEqual("8 kg • ₹12.50", viewModel.itemsDetailLabel)
    }

    func test_switching_shipments_updates_section_headers() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // When
        viewModel.shipments.first?.contents.first?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)
        viewModel.selectedShipmentIndex = 1

        // Then
        assertEqual("1 item", viewModel.itemsCountLabel)
        assertEqual("₹10.00", viewModel.itemsPriceLabel)
        assertEqual("5 kg • ₹10.00", viewModel.itemsDetailLabel)
    }

    func test_topTabItems_are_updated_after_moving_items_to_new_shipment() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)
        XCTAssertEqual(viewModel.topTabItems.count, 1)

        // When
        viewModel.shipments.first?.contents.first?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)

        // Then
        XCTAssertEqual(viewModel.topTabItems.count, 2)
    }

    func test_movingCompletionMessage_is_set_upon_moving_items_and_cleared_upon_tapping_undo() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)
        XCTAssertNil(viewModel.movingCompletionMessage)

        // When
        viewModel.shipments.first?.contents.first?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)

        // Then
        XCTAssertNotNil(viewModel.movingCompletionMessage)

        // When
        viewModel.undoMovingItems()

        // Then
        XCTAssertNil(viewModel.movingCompletionMessage)
    }

    func test_shipments_are_reverted_upon_tapping_undo() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        viewModel.shipments.first?.contents.first?.mainItemRow.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)

        // Confidence checks
        XCTAssertEqual(viewModel.shipments.count, 2)
        XCTAssertEqual(viewModel.shipments[0].index, 0)
        XCTAssertEqual(viewModel.shipments[0].contents.count, 1)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.orderItemID, items[1].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.quantity, 1)
        XCTAssertEqual(viewModel.shipments[1].index, 1)
        XCTAssertEqual(viewModel.shipments[1].contents.count, 1)
        XCTAssertEqual(viewModel.shipments[1].contents[0].packageItem.orderItemID, items[0].orderItemID)
        XCTAssertEqual(viewModel.shipments[1].contents[0].packageItem.quantity, 2)

        // When
        viewModel.undoMovingItems()

        // Then
        XCTAssertEqual(viewModel.shipments.count, 1)

        XCTAssertEqual(viewModel.shipments[0].index, 0)
        XCTAssertEqual(viewModel.shipments[0].contents.count, 2)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.orderItemID, items[0].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.quantity, 2)
        XCTAssertEqual(viewModel.shipments[0].contents[1].packageItem.orderItemID, items[1].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[1].packageItem.quantity, 1)
    }

    // MARK: - `saveShipmentInfo`

    @MainActor
    func test_save_shipping_info_sends_correct_request_to_save_when_there_are_no_fulfilled_shipments() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 3),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           stores: stores,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // Moving items to 2 new shipments
        viewModel.shipments.first?.contents.first?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)

        var receivedShipmentToUpdate: WooShippingUpdateShipment?

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .updateShipment(_, _, shipmentToUpdate, completion):
                receivedShipmentToUpdate = shipmentToUpdate
                completion(.success(["0": [WooShippingShipmentItem.fake()]]))
            default:
                XCTFail("Received unexpected action: \(action)")
            }
        }

        // When
        try await viewModel.saveShipmentInfo()

        // Then
        let expectedShipmentToUpdate = WooShippingUpdateShipment(
            shipmentIdsToUpdate: [:],
            shipments: ["1": [WooShippingShipmentItem(id: 1, subItems: [])],
                        "0": [WooShippingShipmentItem(id: 1, subItems: ["1-sub-0", "1-sub-1"]),
                              WooShippingShipmentItem(id: 2, subItems: [])]]
        )
        XCTAssertEqual(receivedShipmentToUpdate, expectedShipmentToUpdate)
    }

    @MainActor
    func test_save_shipping_info_sends_correct_request_to_save_when_there_is_change_to_fulfilled_shipments_index() async throws {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1),
                     sampleItem(id: 3, weight: 4, value: 5, quantity: 3)]

        let label = ShippingLabel.fake().copy(shipmentID: "2")
        let remoteShipments = [
            WooShippingShipment.fake().copy(index: "0", items: [.init(id: 1, subItems: ["1-sub-0", "1-sub-1"])]),
            WooShippingShipment.fake().copy(index: "1", items: [.init(id: 2, subItems: [])]),
            WooShippingShipment.fake().copy(index: "2", items: [.init(id: 3, subItems: ["3-sub-0", "3-sub-1", "3-sub-2"])], shippingLabel: label)
        ]

        var receivedShipmentToUpdate: WooShippingUpdateShipment?
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .updateShipment(_, _, shipmentToUpdate, completion):
                receivedShipmentToUpdate = shipmentToUpdate
                completion(.success(["0": [WooShippingShipmentItem.fake()]]))
            default:
                XCTFail("Received unexpected action: \(action)")
            }
        }

        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: remoteShipments,
                                                           items: items,
                                                           stores: stores,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // When
        viewModel.mergeAllUnfulfilledShipments()
        try await viewModel.saveShipmentInfo()

        // Then
        let expectedShipmentToUpdate = WooShippingUpdateShipment(
            shipmentIdsToUpdate: ["2": 1],
            shipments: ["0": [WooShippingShipmentItem(id: 1, subItems: ["1-sub-0", "1-sub-1"]),
                              WooShippingShipmentItem(id: 2, subItems: [])],
                        "1": [WooShippingShipmentItem(id: 3, subItems: ["3-sub-0", "3-sub-1", "3-sub-2"])]]
        )
        XCTAssertEqual(receivedShipmentToUpdate, expectedShipmentToUpdate)
    }

    func test_shipmentsToMerge_returns_correct_shipments() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1),
                     sampleItem(id: 3, weight: 4, value: 5, quantity: 3),
                     // Item of a second initial shipment that's purchased
                     sampleItem(id: 4, weight: 4, value: 8.5, quantity: 1)]

        // The second shipment is initially purchased
        let shippingLabel = ShippingLabel.fake().copy(shipmentID: "1")
        let remoteShipments = [
            WooShippingShipment.fake().copy(index: "0", items: [
                WooShippingShipmentItem.fake().copy(id: 1, subItems: ["1-sub-0", "1-sub-1"]),
                WooShippingShipmentItem.fake().copy(id: 2, subItems: []),
                WooShippingShipmentItem.fake().copy(id: 3, subItems: ["3-sub-0", "3-sub-1", "3-sub-2"])
            ]),
            WooShippingShipment.fake().copy(index: "1", items: [
                WooShippingShipmentItem.fake().copy(id: 4, subItems: nil)
            ], shippingLabel: shippingLabel)
        ]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: remoteShipments,
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // Moving items to 2 new shipments
        viewModel.shipments.first?.contents.last?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)
        viewModel.shipments.first?.contents.last?.childItemRows.last?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)

        // Confidence checks
        XCTAssertEqual(viewModel.shipments.count, 4)

        // When
        let shipmentsToMerge = viewModel.shipmentsToMerge(for: viewModel.shipments[3])

        // Then
        XCTAssertEqual(shipmentsToMerge.count, 2)
        XCTAssertEqual(shipmentsToMerge[0].contents.count, 3)
        XCTAssertEqual(shipmentsToMerge[0].contents[0].packageItem.orderItemID, items[0].orderItemID)
        XCTAssertEqual(shipmentsToMerge[0].contents[0].packageItem.quantity, 2)
        XCTAssertEqual(shipmentsToMerge[0].contents[1].packageItem.orderItemID, items[1].orderItemID)
        XCTAssertEqual(shipmentsToMerge[0].contents[1].packageItem.quantity, 1)
        XCTAssertEqual(shipmentsToMerge[0].contents[2].packageItem.orderItemID, items[2].orderItemID)
        XCTAssertEqual(shipmentsToMerge[0].contents[2].packageItem.quantity, 1)
        XCTAssertEqual(shipmentsToMerge[1].contents.count, 1)
        XCTAssertEqual(shipmentsToMerge[1].contents[0].packageItem.orderItemID, items[2].orderItemID)
        XCTAssertEqual(shipmentsToMerge[1].contents[0].packageItem.quantity, 1)
    }

    // MARK: - `removeShipment`

    func test_removeShipment_removes_a_shipment_and_merges_its_contents_to_the_provided_shipment() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1),
                     sampleItem(id: 3, weight: 4, value: 5, quantity: 3)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // Moving items to 2 new shipments
        viewModel.shipments.first?.contents.last?.mainItemRow.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)
        viewModel.shipments.first?.contents.last?.mainItemRow.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)

        // Confidence checks
        XCTAssertEqual(viewModel.shipments.count, 3)

        // When
        viewModel.removeShipment(viewModel.shipments[1], mergeInto: viewModel.shipments[2])

        // Then
        XCTAssertEqual(viewModel.shipments.count, 2)
        XCTAssertEqual(viewModel.shipments[0].index, 0)
        XCTAssertEqual(viewModel.shipments[0].contents.count, 1)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.orderItemID, items[0].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.quantity, 2)
        XCTAssertEqual(viewModel.shipments[1].index, 1)
        XCTAssertEqual(viewModel.shipments[1].contents.count, 2)
        XCTAssertEqual(viewModel.shipments[1].contents[0].packageItem.orderItemID, items[1].orderItemID)
        XCTAssertEqual(viewModel.shipments[1].contents[0].packageItem.quantity, 1)
        XCTAssertEqual(viewModel.shipments[1].contents[1].packageItem.orderItemID, items[2].orderItemID)
        XCTAssertEqual(viewModel.shipments[1].contents[1].packageItem.quantity, 3)
    }

    // MARK: - `mergeAllUnfulfilledShipments`

    func test_mergeAllUnfulfilledShipments_updates_shipments_correctly() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1),
                     sampleItem(id: 3, weight: 4, value: 5, quantity: 3)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                            remoteShipments: [],
                                                            items: items,
                                                            currencySettings: currencySettings,
                                                            shippingSettingsService: shippingSettingsService)

        // Moving items to 2 new shipments
        viewModel.shipments.first?.contents.last?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)
        viewModel.shipments.first?.contents.last?.childItemRows.last?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)

        // Confidence checks
        XCTAssertEqual(viewModel.shipments.count, 3)

        // When
        viewModel.mergeAllUnfulfilledShipments()

        // Then
        XCTAssertEqual(viewModel.shipments.count, 1)
        XCTAssertEqual(viewModel.shipments[0].index, 0)
        XCTAssertEqual(viewModel.shipments[0].contents.count, 3)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.orderItemID, items[0].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.quantity, 2)
        XCTAssertEqual(viewModel.shipments[0].contents[1].packageItem.orderItemID, items[1].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[1].packageItem.quantity, 1)
        XCTAssertEqual(viewModel.shipments[0].contents[2].packageItem.orderItemID, items[2].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[2].packageItem.quantity, 3)
    }

    func test_mergeAllUnfulfilledShipments_updates_shipments_correctly_when_there_exists_a_purchased_shipment() throws {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1),
                     sampleItem(id: 3, weight: 4, value: 5, quantity: 3)]

        let label = ShippingLabel.fake().copy(shipmentID: "1")
        let remoteShipments = [
            WooShippingShipment.fake().copy(index: "0", items: [.init(id: 1, subItems: ["sub-1", "sub-2"])]),
            WooShippingShipment.fake().copy(index: "1", items: [.init(id: 2, subItems: [])], shippingLabel: label),
            WooShippingShipment.fake().copy(index: "2", items: [.init(id: 3, subItems: ["sub-1", "sub-2", "sub-3"])])
        ]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: remoteShipments,
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // Confidence check
        XCTAssertEqual(viewModel.shipments.count, 3)

        // When
        viewModel.mergeAllUnfulfilledShipments()

        // Then
        XCTAssertEqual(viewModel.shipments.count, 2)
        XCTAssertEqual(viewModel.shipments[0].index, 0)
        XCTAssertEqual(viewModel.shipments[0].contents.count, 2)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.orderItemID, items[0].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[0].packageItem.quantity, 2)
        XCTAssertEqual(viewModel.shipments[0].contents[1].packageItem.orderItemID, items[2].orderItemID)
        XCTAssertEqual(viewModel.shipments[0].contents[1].packageItem.quantity, 3)

        XCTAssertEqual(viewModel.shipments[1].index, 1)
        XCTAssertEqual(viewModel.shipments[1].contents.count, 1)
        XCTAssertEqual(viewModel.shipments[1].contents[0].packageItem.orderItemID, items[1].orderItemID)
        XCTAssertEqual(viewModel.shipments[1].contents[0].packageItem.quantity, 1)
    }

    // MARK: - `didPurchaseLabel`
    func test_didPurchaseLabel_updates_fulfilled_shipment_correctly() throws {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1),
                     sampleItem(id: 3, weight: 4, value: 5, quantity: 3)]

        let remoteShipments = [
            WooShippingShipment.fake().copy(index: "0", items: [.init(id: 1, subItems: ["sub-1", "sub-2"])]),
            WooShippingShipment.fake().copy(index: "1", items: [.init(id: 2, subItems: [])]),
        ]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: remoteShipments,
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // Confidence check
        XCTAssertTrue(viewModel.shipments[0].contents.allSatisfy({ $0.mainItemRow.isSelectable }))

        // When
        let shipmentID = viewModel.shipments[0].index
        let purchasedLabelID: Int64 = 325
        let label = ShippingLabel.fake().copy(shippingLabelID: purchasedLabelID)
        viewModel.didPurchaseLabel(for: shipmentID, label: label)

        // Then
        XCTAssertFalse(viewModel.containsUnsavedChanges)
        XCTAssertEqual(viewModel.shipments.count, 2)
        XCTAssertEqual(viewModel.shipments[0].index, 0)
        XCTAssertEqual(viewModel.shipments[0].purchasedLabel, label)
        XCTAssertFalse(viewModel.shipments[0].contents[0].mainItemRow.isSelectable)
        XCTAssertTrue(viewModel.shipments[0].contents[0].childItemRows.allSatisfy({ !$0.isSelectable }))

        XCTAssertEqual(viewModel.shipments[1].index, 1)
        XCTAssertEqual(viewModel.shipments[1].contents.count, 1)
        XCTAssertTrue(viewModel.shipments[1].contents[0].mainItemRow.isSelectable)
        XCTAssertNil(viewModel.shipments[1].purchasedLabel)
    }

    // MARK: - `didRequestRefund`
    func test_didRequestRefund_updates_shipment_correctly() throws {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1),
                     sampleItem(id: 3, weight: 4, value: 5, quantity: 3)]

        let label = ShippingLabel.fake().copy(shipmentID: "0")
        let remoteShipments = [
            WooShippingShipment.fake().copy(index: "0", items: [.init(id: 1, subItems: ["sub-1", "sub-2"])], shippingLabel: label),
            WooShippingShipment.fake().copy(index: "1", items: [.init(id: 2, subItems: [])]),
        ]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: remoteShipments,
                                                           items: items,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // Confidence check
        XCTAssertTrue(viewModel.shipments[0].contents.allSatisfy({ $0.mainItemRow.isSelectable == false }))

        // When
        let shipmentID = viewModel.shipments[0].index
        viewModel.didRequestRefund(for: shipmentID)

        // Then
        XCTAssertFalse(viewModel.containsUnsavedChanges)
        XCTAssertEqual(viewModel.shipments.count, 2)
        XCTAssertNil(viewModel.shipments[0].purchasedLabel)
        XCTAssertTrue(viewModel.shipments[0].contents[0].mainItemRow.isSelectable)
        XCTAssertTrue(viewModel.shipments[0].contents[0].childItemRows.allSatisfy({ $0.isSelectable }))


        XCTAssertEqual(viewModel.shipments[1].contents.count, 1)
        XCTAssertTrue(viewModel.shipments[1].contents[0].mainItemRow.isSelectable)
        XCTAssertNil(viewModel.shipments[1].purchasedLabel)
    }

    // MARK: - `enableDoneButton`

    @MainActor
    func test_containsUnsavedChanges_is_false_initially() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 3),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           stores: stores,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // Then
        XCTAssertFalse(viewModel.containsUnsavedChanges)
    }

    @MainActor
    func test_containsUnsavedChanges_turns_true_when_changes_made_to_shipments() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 3),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           stores: stores,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // When
        viewModel.shipments.first?.contents.first?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)

        // Then
        XCTAssertTrue(viewModel.containsUnsavedChanges)

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .updateShipment(_, _, _, completion):
                completion(.success(["0": [WooShippingShipmentItem.fake()]]))
            default:
                XCTFail("Received unexpected action: \(action)")
            }
        }

        // When
        try await viewModel.saveShipmentInfo()

        // Then
        XCTAssertFalse(viewModel.containsUnsavedChanges)
    }

    @MainActor
    func test_containsUnsavedChanges_turns_false_when_shipment_changes_are_saved_to_remote() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 3),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           stores: stores,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // When
        viewModel.shipments.first?.contents.first?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)

        // Then
        XCTAssertTrue(viewModel.containsUnsavedChanges)

        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .updateShipment(_, _, _, completion):
                completion(.success(["0": [WooShippingShipmentItem.fake()]]))
            default:
                XCTFail("Received unexpected action: \(action)")
            }
        }

        // When
        try await viewModel.saveShipmentInfo()

        // Then
        XCTAssertFalse(viewModel.containsUnsavedChanges)
    }

    @MainActor
    func test_containsUnsavedChanges_turns_false_when_shipment_changes_are_undone() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 3),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]
        let viewModel = WooShippingSplitShipmentsViewModel(order: sampleOrder,
                                                           remoteShipments: [],
                                                           items: items,
                                                           stores: stores,
                                                           currencySettings: currencySettings,
                                                           shippingSettingsService: shippingSettingsService)

        // When
        viewModel.shipments.first?.contents.first?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)
        viewModel.undoMovingItems()

        // Then
        XCTAssertFalse(viewModel.containsUnsavedChanges)
    }

    // MARK: - `isShipmentDeleteOptionAvailable`

    func test_isShipmentDeleteOptionAvailable_returns_false_for_purchased_shipment() throws {
        // Given
        let items = [
            sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
            sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)
        ]

        let label = ShippingLabel.fake().copy(shipmentID: "0")
        let remoteShipments = [
            WooShippingShipment.fake().copy(index: "0", items: [.init(id: 1, subItems: ["sub-1", "sub-2"])], shippingLabel: label),
            WooShippingShipment.fake().copy(index: "1", items: [.init(id: 2, subItems: [])]),
        ]

        let viewModel = WooShippingSplitShipmentsViewModel(
            order: sampleOrder,
            remoteShipments: remoteShipments,
            items: items,
            currencySettings: currencySettings,
            shippingSettingsService: shippingSettingsService
        )

        // When
        let purchasedShipment = viewModel.shipments[0]  // First shipment is purchased

        // Then
        XCTAssertFalse(viewModel.isShipmentDeleteOptionAvailable(for: purchasedShipment))
    }

    func test_isShipmentDeleteOptionAvailable_returns_true_for_unfulfilled_shipment_when_there_are_multiple() throws {
        // Given
        let items = [
            sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
            sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)
        ]

        let viewModel = WooShippingSplitShipmentsViewModel(
            order: sampleOrder,
            remoteShipments: [],
            items: items,
            currencySettings: currencySettings,
            shippingSettingsService: shippingSettingsService
        )

        // When
        viewModel.shipments.first?.contents.last?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)

        // Then
        XCTAssertEqual(viewModel.shipments.count, 2)
        XCTAssertTrue(viewModel.isShipmentDeleteOptionAvailable(for: viewModel.shipments[0]))
        XCTAssertTrue(viewModel.isShipmentDeleteOptionAvailable(for: viewModel.shipments[1]))
    }

    func test_isShipmentDeleteOptionAvailable_returns_false_for_last_unfulfilled_shipment() throws {
        // Given
        let items = [
            sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
            sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)
        ]

        let label = ShippingLabel.fake().copy(shipmentID: "1")
        let remoteShipments = [
            WooShippingShipment.fake().copy(index: "0", items: [.init(id: 1, subItems: ["sub-1", "sub-2"])], shippingLabel: label),
            WooShippingShipment.fake().copy(index: "1", items: [.init(id: 2, subItems: [])]),
        ]

        let viewModel = WooShippingSplitShipmentsViewModel(
            order: sampleOrder,
            remoteShipments: remoteShipments,
            items: items,
            currencySettings: currencySettings,
            shippingSettingsService: shippingSettingsService
        )

        // When
        let unfulfilledShipment = viewModel.shipments[0]  // First shipment is unfulfilled

        // Then
        XCTAssertFalse(viewModel.isShipmentDeleteOptionAvailable(for: unfulfilledShipment))
    }

    // MARK: - `instructions`

    func test_instructions_is_nil_when_there_exists_more_than_one_shipment() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]

        let remoteShipments = [
            WooShippingShipment.fake().copy(index: "0", items: [.init(id: 1, subItems: ["sub-1", "sub-2"])]),
            WooShippingShipment.fake().copy(index: "1", items: [.init(id: 2, subItems: [])]),
        ]

        let viewModel = WooShippingSplitShipmentsViewModel(
            order: sampleOrder,
            remoteShipments: remoteShipments,
            items: items,
            currencySettings: currencySettings,
            shippingSettingsService: shippingSettingsService
        )

        // When
        viewModel.onAppear()

        // Then
        XCTAssertNil(viewModel.instructions)
    }

    func test_instructions_is_not_nil_when_there_exists_only_one_shipment() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]

        let viewModel = WooShippingSplitShipmentsViewModel(
            order: sampleOrder,
            remoteShipments: [],
            items: items,
            currencySettings: currencySettings,
            shippingSettingsService: shippingSettingsService
        )

        // When
        viewModel.onAppear()

        // Then
        XCTAssertNotNil(viewModel.instructions)
    }

    // MARK: - `revertChanges`

    func test_revertChanges_restores_shipments_and_resets_selected_index() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]

        let viewModel = WooShippingSplitShipmentsViewModel(
            order: sampleOrder,
            remoteShipments: [],
            items: items,
            currencySettings: currencySettings,
            shippingSettingsService: shippingSettingsService
        )

        // Store the initial state
        let initialShipmentCount = viewModel.shipments.count
        let initialFirstShipmentContentsCount = viewModel.shipments.first?.contents.count

        // When - Make changes to shipments
        viewModel.shipments.first?.contents.first?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)
        viewModel.selectedShipmentIndex = 1

        // Verify changes were made
        XCTAssertEqual(viewModel.shipments.count, 2)
        XCTAssertEqual(viewModel.selectedShipmentIndex, 1)

        // When - Revert changes
        viewModel.revertChanges()

        // Then - Verify state is restored
        XCTAssertEqual(viewModel.shipments.count, initialShipmentCount)
        XCTAssertEqual(viewModel.shipments.first?.contents.count, initialFirstShipmentContentsCount)
        XCTAssertEqual(viewModel.selectedShipmentIndex, 0)
    }

    // MARK: - `isMergeAllUnfulfilledAvailable`

    func test_isMergeAllUnfulfilledAvailable_returns_false_when_no_unfulfilled_shipments() throws {
        // Given
        let label = ShippingLabel.fake().copy(shipmentID: "0")
        let remoteShipments = [
            WooShippingShipment.fake().copy(index: "0", items: [.init(id: 1, subItems: ["sub-1", "sub-2"])], shippingLabel: label),
        ]

        let viewModel = WooShippingSplitShipmentsViewModel(
            order: sampleOrder,
            remoteShipments: remoteShipments,
            items: [sampleItem(id: 1, weight: 5, value: 10, quantity: 2)],
            currencySettings: currencySettings,
            shippingSettingsService: shippingSettingsService
        )

        // Then
        XCTAssertFalse(viewModel.isMergeAllUnfulfilledAvailable())
    }

    func test_isMergeAllUnfulfilledAvailable_returns_false_when_only_one_unfulfilled_shipment() {
        // Given
        let viewModel = WooShippingSplitShipmentsViewModel(
            order: sampleOrder,
            remoteShipments: [],
            items: [sampleItem(id: 1, weight: 5, value: 10, quantity: 2)],
            currencySettings: currencySettings,
            shippingSettingsService: shippingSettingsService
        )

        // Then
        XCTAssertFalse(viewModel.isMergeAllUnfulfilledAvailable())
    }

    func test_isMergeAllUnfulfilledAvailable_returns_false_when_only_two_unfulfilled_shipments() {
        // Given
        let items = [
            sampleItem(id: 1, weight: 5, value: 10, quantity: 2)
        ]

        let viewModel = WooShippingSplitShipmentsViewModel(
            order: sampleOrder,
            remoteShipments: [],
            items: items,
            currencySettings: currencySettings,
            shippingSettingsService: shippingSettingsService
        )

        // When
        viewModel.shipments.first?.contents.last?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)

        // Then
        XCTAssertFalse(viewModel.isMergeAllUnfulfilledAvailable())
    }

    func test_isMergeAllUnfulfilledAvailable_returns_true_when_multiple_unfulfilled_shipments() {
        // Given
        let items = [
            sampleItem(id: 1, weight: 5, value: 10, quantity: 3),
            sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)
        ]

        let viewModel = WooShippingSplitShipmentsViewModel(
            order: sampleOrder,
            remoteShipments: [],
            items: items,
            currencySettings: currencySettings,
            shippingSettingsService: shippingSettingsService
        )

        // When
        viewModel.shipments.first?.contents.last?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)
        viewModel.shipments.first?.contents.last?.childItemRows.first?.handleTap()
        viewModel.moveSelectedItems(to: .newShipment)

        // Then
        XCTAssertTrue(viewModel.isMergeAllUnfulfilledAvailable())
    }

    // MARK: - removableShipments

    func test_removableShipments_returns_empty_when_only_one_unfulfilled_shipment() {
        // Given
        let items = [
            sampleItem(
                id: 1,
                weight: 5,
                value: 10,
                quantity: 2
            )
        ]
        let viewModel = WooShippingSplitShipmentsViewModel(
            order: sampleOrder,
            remoteShipments: [],
            items: items,
            currencySettings: currencySettings,
            shippingSettingsService: shippingSettingsService
        )

        // Then
        XCTAssertTrue(viewModel.removableShipments.isEmpty)
    }

    func test_removableShipments_returns_all_unfulfilled_shipments_when_multiple_exist() {
        // Given
        let items = [
            sampleItem(
                id: 1,
                weight: 5,
                value: 10,
                quantity: 2
            )
        ]
        let remoteShipments = [
            WooShippingShipment.fake().copy(index: "0", items: [
                WooShippingShipmentItem.fake().copy(
                    id: 1,
                    subItems: nil
                )
            ]),
            WooShippingShipment.fake().copy(index: "1", items: [
                WooShippingShipmentItem.fake().copy(
                    id: 1,
                    subItems: nil
                )
            ])
        ]
        let viewModel = WooShippingSplitShipmentsViewModel(
            order: sampleOrder,
            remoteShipments: remoteShipments,
            items: items,
            currencySettings: currencySettings,
            shippingSettingsService: shippingSettingsService
        )

        // Then
        XCTAssertEqual(viewModel.removableShipments.count, 2)
    }

    func test_removableShipments_excludes_purchased_shipments() {
        // Given
        let items = [
            sampleItem(
                id: 1,
                weight: 5,
                value: 10,
                quantity: 2
            )
        ]
        let shippingLabel = ShippingLabel.fake().copy(shipmentID: "0")
        let remoteShipments = [
            WooShippingShipment.fake().copy(index: "0", items: [
                WooShippingShipmentItem.fake().copy(
                    id: 1,
                    subItems: nil
                )
            ], shippingLabel: shippingLabel),
            WooShippingShipment.fake().copy(index: "1", items: [
                WooShippingShipmentItem.fake().copy(
                    id: 1,
                    subItems: nil
                )
            ])
        ]
        let viewModel = WooShippingSplitShipmentsViewModel(
            order: sampleOrder,
            remoteShipments: remoteShipments,
            items: items,
            currencySettings: currencySettings,
            shippingSettingsService: shippingSettingsService
        )

        // Then
        XCTAssertTrue(viewModel.removableShipments.isEmpty)
    }

    // MARK: - shouldShowRemoveShipmentMenu

    func test_shouldShowRemoveShipmentMenu_returns_true_when_removable_shipments_exist_and_merge_not_available() {
        // Given
        let items = [
            sampleItem(
                id: 1,
                weight: 5,
                value: 10,
                quantity: 2
            )
        ]
        let remoteShipments = [
            WooShippingShipment.fake().copy(index: "0", items: [
                WooShippingShipmentItem.fake().copy(
                    id: 1,
                    subItems: nil
                )
            ]),
            WooShippingShipment.fake().copy(index: "1", items: [
                WooShippingShipmentItem.fake().copy(
                    id: 1,
                    subItems: nil
                )
            ])
        ]
        let viewModel = WooShippingSplitShipmentsViewModel(
            order: sampleOrder,
            remoteShipments: remoteShipments,
            items: items,
            currencySettings: currencySettings,
            shippingSettingsService: shippingSettingsService
        )

        // Then
        XCTAssertTrue(viewModel.shouldShowRemoveShipmentMenu)
    }

    func test_shouldShowRemoveShipmentMenu_returns_true_when_removable_shipments_exist_and_merge_available() {
        // Given
        let items = [
            sampleItem(
                id: 1,
                weight: 5,
                value: 10,
                quantity: 3
            )
        ]
        let remoteShipments = [
            WooShippingShipment.fake().copy(index: "0", items: [
                WooShippingShipmentItem.fake().copy(
                    id: 1,
                    subItems: ["sub-1"]
                )
            ]),
            WooShippingShipment.fake().copy(index: "1", items: [
                WooShippingShipmentItem.fake().copy(
                    id: 1,
                    subItems: ["sub-2"]
                )
            ]),
            WooShippingShipment.fake().copy(index: "2", items: [
                WooShippingShipmentItem.fake().copy(
                    id: 1,
                    subItems: ["sub-3"]
                )
            ])
        ]
        let viewModel = WooShippingSplitShipmentsViewModel(
            order: sampleOrder,
            remoteShipments: remoteShipments,
            items: items,
            currencySettings: currencySettings,
            shippingSettingsService: shippingSettingsService
        )

        // Then
        XCTAssertTrue(viewModel.shouldShowRemoveShipmentMenu)
    }

    func test_shouldShowRemoveShipmentMenu_returns_false_when_no_removable_shipments_and_merge_not_available() {
        // Given
        let items = [
            sampleItem(
                id: 1,
                weight: 5,
                value: 10,
                quantity: 2
            )
        ]
        let viewModel = WooShippingSplitShipmentsViewModel(
            order: sampleOrder,
            remoteShipments: [],
            items: items,
            currencySettings: currencySettings,
            shippingSettingsService: shippingSettingsService
        )

        // Then
        XCTAssertFalse(viewModel.shouldShowRemoveShipmentMenu)
    }
}

private extension WooShippingSplitShipmentsViewModelTests {
    func sampleItem(id: Int64, weight: Double, value: Double, quantity: Decimal) -> ShippingLabelPackageItem {
        ShippingLabelPackageItem(productOrVariationID: id,
                                 orderItemID: id,
                                 name: "Item",
                                 weight: weight,
                                 quantity: quantity,
                                 value: value,
                                 dimensions: ProductDimensions(length: "20", width: "35", height: "5"),
                                 attributes: [],
                                 imageURL: nil)
    }
}

private final class MockDataSource: WooShippingItemsDataSource {
    var items: [ShippingLabelPackageItem]
    var currency: String

    init(items: [ShippingLabelPackageItem],
         currency: String = "GBP") {
        self.items = items
        self.currency = currency
    }
}
