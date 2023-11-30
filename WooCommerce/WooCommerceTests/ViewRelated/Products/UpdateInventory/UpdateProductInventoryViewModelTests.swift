import XCTest
import Yosemite
import Fakes
@testable import WooCommerce

final class UpdateProductInventoryViewModelTests: XCTestCase {
    private var viewModel: UpdateProductInventoryViewModel!
    let siteID: Int64 = 1

    func test_quantity_when_we_pass_a_product_it_shows_right_quantity() {
        // Given
        let stockQuantity = Decimal(12)
        let product = Product.fake().copy(siteID: siteID, stockQuantity: stockQuantity)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID)

        // Then
        XCTAssertEqual(viewModel.quantity, stockQuantity.formatted())
    }

    func test_quantity_when_we_pass_a_variation_it_shows_right_quantity() {
        // Given
        let stockQuantity = Decimal(12)
        let variation = ProductVariation.fake().copy(siteID: siteID, stockQuantity: stockQuantity)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: variation, siteID: siteID)

        // Then
        XCTAssertEqual(viewModel.quantity, stockQuantity.formatted())
    }

    func test_sku_when_we_pass_a_product_it_shows_right_sku() {
        // Given
        let sku = "test-sku"
        let product = Product.fake().copy(siteID: siteID, sku: sku)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID)

        // Then
        XCTAssertEqual(viewModel.sku, sku)
    }

    func test_sku_when_we_pass_a_variation_it_shows_right_sku() {
        // Given
        let sku = "test-sku"
        let variation = ProductVariation.fake().copy(siteID: siteID, sku: sku)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: variation, siteID: siteID)

        // Then
        XCTAssertEqual(viewModel.sku, sku)
    }

    func test_imageURL_when_we_pass_a_product_it_shows_right_url() {
        // Given
        let url = "www.picture.com"
        let product = Product.fake().copy(siteID: siteID, images: [ProductImage.fake().copy(src: url)])
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID)

        // Then
        XCTAssertEqual(viewModel.imageURL?.absoluteString, url)
    }

    func test_imageURL_when_we_pass_a_variation_it_shows_right_url() {
        // Given
        let url = "www.picture.com"
        let variation = ProductVariation.fake().copy(siteID: siteID, image: ProductImage.fake().copy(src: url))
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: variation, siteID: siteID)

        // Then
        XCTAssertEqual(viewModel.imageURL?.absoluteString, url)
    }

    func test_name_when_we_pass_a_product_it_shows_right_name() {
        // Given
        let name = "test-name"
        let product = Product.fake().copy(siteID: siteID, name: name)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID)

        waitUntil {
            viewModel.name == name
        }
    }

    func test_name_when_we_pass_a_variation_it_shows_the_parent_product_name() {
        // Given
        let parentProductID: Int64 = 12345
        let name = "test-name"
        let parentProduct = Product.fake().copy(siteID: siteID, productID: parentProductID, name: name)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: ProductAction.self) { [weak self ]action in
            guard let self = self else { return }
            switch action {
            case let .retrieveProduct(passingSiteID, productID, onCompletion):
                if passingSiteID == self.siteID,
                   productID == parentProductID {
                    onCompletion(.success(parentProduct))
                }
            default:
                break
            }
        }

        let product = ProductVariation.fake().copy(siteID: siteID, productID: parentProductID)
        let viewModel = UpdateProductInventoryViewModel(inventoryItem: product, siteID: siteID, stores: stores)

        waitUntil {
            viewModel.name == name
        }
    }
}
