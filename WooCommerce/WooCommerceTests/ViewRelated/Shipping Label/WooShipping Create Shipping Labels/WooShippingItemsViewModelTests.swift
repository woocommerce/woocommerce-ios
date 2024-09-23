import XCTest
@testable import WooCommerce
import WooFoundation
import Yosemite

final class WooShippingItemsViewModelTests: XCTestCase {

    private var currencySettings: CurrencySettings!
    private var shippingSettingsService: MockShippingSettingsService!

    override func setUp() {
        currencySettings = CurrencySettings()
        shippingSettingsService = MockShippingSettingsService()
    }

    func test_inits_with_expected_values() throws {
        // Given
        let items = [sampleItem(id: 1, weight: 4, value: 10, quantity: 1),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]
        let dataSource = MockDataSource(items: items)

        // When
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource,
                                                  currencySettings: currencySettings,
                                                  shippingSettingsService: shippingSettingsService)

        // Then
        assertEqual("2 items", viewModel.itemsCountLabel)
        assertEqual("7 oz • $12.50", viewModel.itemsDetailLabel)
        assertEqual(2, viewModel.itemRows.count)
    }

    func test_total_items_count_handles_items_with_quantity_greater_than_one() {
        // Given
        let items = [sampleItem(id: 1, weight: 1, value: 1, quantity: 1),
                     sampleItem(id: 2, weight: 1, value: 1, quantity: 2)]
        let dataSource = MockDataSource(items: items)

        // When
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource, currencySettings: currencySettings)

        // Then
        assertEqual("3 items", viewModel.itemsCountLabel)
    }

    func test_total_items_details_handles_items_with_quantity_greater_than_one() {
        // Given
        let items = [sampleItem(id: 1, weight: 5, value: 10, quantity: 2),
                     sampleItem(id: 2, weight: 3, value: 2.5, quantity: 1)]
        let dataSource = MockDataSource(items: items)

        // When
        let viewModel = WooShippingItemsViewModel(dataSource: dataSource,
                                                  currencySettings: currencySettings,
                                                  shippingSettingsService: shippingSettingsService)

        // Then
        assertEqual("13 oz • $22.50", viewModel.itemsDetailLabel)
    }

}

private extension WooShippingItemsViewModelTests {
    func sampleItem(id: Int64, weight: Double, value: Double, quantity: Decimal) -> ShippingLabelPackageItem {
        ShippingLabelPackageItem(productOrVariationID: id,
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

    init(items: [ShippingLabelPackageItem]) {
        self.items = items
    }
}
