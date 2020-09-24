import XCTest

@testable import WooCommerce
import Yosemite

final class ProductFormViewModelTests: XCTestCase {
    // MARK: `canViewProductInStore`

    func test_edit_product_form_with_published_status_can_view_product_in_store() {
        // Arrange
        let product = MockProduct().product(name: "Test", status: .publish)
        let viewModel = createViewModel(product: product, formType: .edit)

        // Action
        let canViewProductInStore = viewModel.canViewProductInStore()

        // Assert
        XCTAssertTrue(canViewProductInStore)
    }

    func test_add_product_form_with_published_status_cannot_view_product_in_store() {
        // Arrange
        let product = MockProduct().product(name: "Test", status: .publish)
        let viewModel = createViewModel(product: product, formType: .add)

        // Action
        let canViewProductInStore = viewModel.canViewProductInStore()

        // Assert
        XCTAssertFalse(canViewProductInStore)
    }

    func test_edit_product_form_with_non_published_status_cannot_view_product_in_store() {
        // Arrange
        let product = MockProduct().product(name: "Test", status: .pending)
        let viewModel = createViewModel(product: product, formType: .edit)

        // Action
        let canViewProductInStore = viewModel.canViewProductInStore()

        // Assert
        XCTAssertFalse(canViewProductInStore)
    }

    func test_add_product_form_with_non_published_status_cannot_view_product_in_store() {
        // Arrange
        let product = MockProduct().product(name: "Test", status: .pending)
        let viewModel = createViewModel(product: product, formType: .add)

        // Action
        let canViewProductInStore = viewModel.canViewProductInStore()

        // Assert
        XCTAssertFalse(canViewProductInStore)
    }

    // MARK: `canShareProduct`

    func test_edit_product_form_with_published_status_can_share_product() {
        // Arrange
        let product = MockProduct().product(name: "Test", status: .publish)
        let viewModel = createViewModel(product: product, formType: .edit)

        // Action
        let canShareProduct = viewModel.canShareProduct()

        // Assert
        XCTAssertTrue(canShareProduct)
    }

    func test_add_product_form_with_published_status_cannot_share_product() {
        // Arrange
        let product = MockProduct().product(name: "Test", status: .publish)
        let viewModel = createViewModel(product: product, formType: .add)

        // Action
        let canShareProduct = viewModel.canShareProduct()

        // Assert
        XCTAssertFalse(canShareProduct)
    }

    func test_edit_product_form_with_non_published_status_can_share_product() {
        // Arrange
        let product = MockProduct().product(name: "Test", status: .pending)
        let viewModel = createViewModel(product: product, formType: .edit)

        // Action
        let canShareProduct = viewModel.canShareProduct()

        // Assert
        XCTAssertTrue(canShareProduct)
    }

    func test_add_product_form_with_non_published_status_cannot_share_product() {
        // Arrange
        let product = MockProduct().product(name: "Test", status: .pending)
        let viewModel = createViewModel(product: product, formType: .add)

        // Action
        let canShareProduct = viewModel.canShareProduct()

        // Assert
        XCTAssertFalse(canShareProduct)
    }

    // MARK: `canDeleteProduct`

    func test_edit_product_form_with_published_status_can_delete_product() {
        // Arrange
        let product = MockProduct().product(name: "Test", status: .publish)
        let viewModel = createViewModel(product: product, formType: .edit)

        // Action
        let canDeleteProduct = viewModel.canDeleteProduct()

        // Assert
        XCTAssertTrue(canDeleteProduct)
    }

    func test_add_product_form_with_published_status_cannot_delete_product() {
        // Arrange
        let product = MockProduct().product(name: "Test", status: .publish)
        let viewModel = createViewModel(product: product, formType: .add)

        // Action
        let canDeleteProduct = viewModel.canDeleteProduct()

        // Assert
        XCTAssertFalse(canDeleteProduct)
    }

    func test_edit_product_form_with_non_published_status_can_delete_product() {
        // Arrange
        let product = MockProduct().product(name: "Test", status: .pending)
        let viewModel = createViewModel(product: product, formType: .edit)

        // Action
        let canDeleteProduct = viewModel.canDeleteProduct()

        // Assert
        XCTAssertTrue(canDeleteProduct)
    }

    func test_add_product_form_with_non_published_status_cannot_delete_product() {
        // Arrange
        let product = MockProduct().product(name: "Test", status: .pending)
        let viewModel = createViewModel(product: product, formType: .add)

        // Action
        let canDeleteProduct = viewModel.canDeleteProduct()

        // Assert
        XCTAssertFalse(canDeleteProduct)
    }
}

private extension ProductFormViewModelTests {
    func createViewModel(product: Product, formType: ProductFormType) -> ProductFormViewModel {
        let model = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: model)
        return ProductFormViewModel(product: model,
                                    formType: formType,
                                    productImageActionHandler: productImageActionHandler,
                                    isEditProductsRelease3Enabled: true,
                                    isEditProductsRelease5Enabled: true)
    }
}
