import XCTest
import WooFoundation
import Yosemite
@testable import WooCommerce

final class WooShippingItemRowViewModelTests: XCTestCase {

    private var currencySettings: CurrencySettings!
    private var shippingSettingsService: MockShippingSettingsService!

    override func setUp() {
        currencySettings = CurrencySettings()
        shippingSettingsService = MockShippingSettingsService()
    }

    func test_inits_with_expected_values() {
        // Given
        let row = WooShippingItemRowViewModel(imageUrl: URL(string: "https://woocommerce.com/woo.jpg"),
                                              quantityLabel: "3",
                                              name: "Little Nap Brazil",
                                              detailsLabel: "15 x 10 x 8 in • Espresso",
                                              weightLabel: "30 oz",
                                              priceLabel: "$60.00")

        // Then
        assertEqual(URL(string: "https://woocommerce.com/woo.jpg"), row.imageUrl)
        assertEqual("3", row.quantityLabel)
        assertEqual("Little Nap Brazil", row.name)
        assertEqual("15 x 10 x 8 in • Espresso", row.detailsLabel)
        assertEqual("30 oz", row.weightLabel)
        assertEqual("$60.00", row.priceLabel)
    }

    func test_inits_from_ShippingLabelPackageItem_with_expected_values() {
        // Given
        let item = ShippingLabelPackageItem(productOrVariationID: 1,
                                            name: "Little Nap Brazil",
                                            weight: 10,
                                            quantity: 3,
                                            value: 20,
                                            dimensions: ProductDimensions(length: "15", width: "10", height: "8"),
                                            attributes: [VariationAttributeViewModel(name: "Roast", value: "Espresso"),
                                                         VariationAttributeViewModel(name: "Size", value: "10 oz")],
                                            imageURL: URL(string: "https://woocommerce.com/woo.jpg"))
        let row = WooShippingItemRowViewModel(item: item, shippingSettingsService: shippingSettingsService, currencySettings: currencySettings)

        // Then
        assertEqual(URL(string: "https://woocommerce.com/woo.jpg"), row.imageUrl)
        assertEqual("3", row.quantityLabel)
        assertEqual("Little Nap Brazil", row.name)
        assertEqual("15 x 10 x 8 in • Espresso, 10 oz", row.detailsLabel)
        assertEqual("30 oz", row.weightLabel)
        assertEqual("$60.00", row.priceLabel)
    }

}
