import XCTest
@testable import WooCommerce
@testable import protocol Yosemite.POSItemProvider
@testable import protocol Yosemite.POSItem

final class ItemSelectorViewModelTests: XCTestCase {
    private var itemProvider: POSItemProvider!
    private var itemSelector: ItemSelectorViewModel!

    override func setUp() {
        super.setUp()
        itemProvider = MockPOSItemProvider()
        itemSelector = ItemSelectorViewModel(itemProvider: itemProvider)
    }

    override func tearDown() {
        itemProvider = nil
        itemSelector = nil
        super.tearDown()
    }

    func test_isSyncingItems_is_true_when_populatePointOfSaleItems_is_invoked_then_switches_to_false_when_completed() async {
        XCTAssertEqual(itemSelector.isSyncingItems, true, "Precondition")

        // Given/When
        await itemSelector.populatePointOfSaleItems()

        // Then
        XCTAssertEqual(itemSelector.isSyncingItems, false)
    }

}

private extension ItemSelectorViewModelTests {
    final class MockPOSItemProvider: POSItemProvider {
        var items: [POSItem] = []
        var provideItemsInvocationCount = 0

        func providePointOfSaleItems() async throws -> [Yosemite.POSItem] {
            provideItemsInvocationCount += 1
            return []
        }
    }
}
