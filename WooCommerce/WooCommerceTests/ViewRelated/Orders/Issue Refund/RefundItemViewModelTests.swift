import XCTest
import Yosemite
import Fakes

@testable import WooCommerce

/// Test cases for `RefundItemViewModel`
///
final class RefundItemViewModelTests: XCTestCase {
    func test_viewModel_is_created_with_correct_initial_values() {
        // Given
        let refundable = RefundableOrderItem(item: sampleItem(), quantity: 4)
        let product = sampleProduct()
        let currencySettings = CurrencySettings()

        // When
        let viewModel = RefundItemViewModel(refundable: refundable, product: product, refundQuantity: 3, currency: "usd", currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.productImage, product.images.first?.src)
        XCTAssertEqual(viewModel.productTitle, refundable.item.name)
        XCTAssertEqual(viewModel.quantityToRefund, "3")

        let localizedFormat = NSLocalizedString("%d x %@ each", comment: "")
        XCTAssertEqual(viewModel.productQuantityAndPrice, String(format: localizedFormat, refundable.quantity, "$\(refundable.item.price)"))
    }
}

// MARK: Sample Objects
private extension RefundItemViewModelTests {

    func sampleProduct() -> Product {
        Product.fake().copy(images: [sampleProductImage()])
    }

    func sampleItem() -> OrderItem {
        MockOrderItem.sampleItem(name: "Sample Item", quantity: 2, price: 10.55)
    }

    func sampleProductImage() -> ProductImage {
        ProductImage(imageID: 0, dateCreated: Date(), dateModified: nil, src: "https://www.woo.com/img.jpg", name: nil, alt: nil)
    }
}
