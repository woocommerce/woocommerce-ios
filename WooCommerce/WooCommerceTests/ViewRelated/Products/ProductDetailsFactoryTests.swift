import XCTest
import Fakes
import Yosemite
import WooFoundation
@testable import WooCommerce

@MainActor
final class ProductDetailsFactoryTests: XCTestCase {
    // MARK: Simple product type

    func test_factory_creates_product_form_for_simple_product() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.simple.rawValue)

        // Action
        let viewController = ProductDetailsFactory.productDetails(product: product,
                                                                  presentationStyle: .navigationStack,
                                                                  forceReadOnly: false,
                                                                  onDuplicateCompletion: { _, _ in })

        // Assert
        XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
    }

    // MARK: External/affiliate product type

    func test_factory_creates_product_form_for_affiliate_product() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.affiliate.rawValue)

        // Action
        let viewController = ProductDetailsFactory.productDetails(product: product,
                                                                  presentationStyle: .navigationStack,
                                                                  forceReadOnly: false,
                                                                  onDuplicateCompletion: { _, _ in })

        // Assert
        XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
    }

    // MARK: Grouped product type

    func test_factory_creates_product_form_for_grouped_product() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.grouped.rawValue)

        // Action
        let viewController = ProductDetailsFactory.productDetails(product: product,
                                                                  presentationStyle: .navigationStack,
                                                                  forceReadOnly: false,
                                                                  onDuplicateCompletion: { _, _ in })
        // Assert
        XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
    }

    // MARK: Variable product type

    func test_factory_creates_product_form_for_variable_product() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.variable.rawValue)

        // Action
        let viewController = ProductDetailsFactory.productDetails(product: product,
                                                                  presentationStyle: .navigationStack,
                                                                  forceReadOnly: false,
                                                                  onDuplicateCompletion: { _, _ in })

        // Assert
        XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
    }

    // MARK: Non-core product type

    func test_factory_creates_product_form_for_non_core_product() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: "other")

        // Action
        let viewController = ProductDetailsFactory.productDetails(product: product,
                                                                  presentationStyle: .navigationStack,
                                                                  forceReadOnly: false,
                                                                  onDuplicateCompletion: { _, _ in })
        // Assert
        XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
    }

    func test_factory_creates_readonly_product_details_for_product_when_forceReadOnly_is_on() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.simple.rawValue)

        // Action
        let viewController = ProductDetailsFactory.productDetails(product: product,
                                                                  presentationStyle: .navigationStack,
                                                                  forceReadOnly: true,
                                                                  onDuplicateCompletion: { _, _ in })
        // Assert
        XCTAssertTrue(viewController is ProductFormViewController<ProductFormViewModel>)
    }

    func test_factory_configures_requested_form_type_and_injected_dependencies() throws {
        // Given
        let product = Product.fake()
        let currencySettings = CurrencySettings(currencyCode: .EUR,
                                                currencyPosition: .right,
                                                thousandSeparator: ",",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 2)
        let productImageUploader = MockProductImageUploader()

        // When
        let viewController = ProductDetailsFactory.productDetails(product: product,
                                                                  presentationStyle: .navigationStack,
                                                                  formType: .add,
                                                                  isAIContent: true,
                                                                  isLocalProduct: true,
                                                                  currencySettings: currencySettings,
                                                                  productImageUploader: productImageUploader,
                                                                  onDuplicateCompletion: { _, _ in })
        let productForm = try XCTUnwrap(viewController as? ProductFormViewController<ProductFormViewModel>)
        let viewModel: ProductFormViewModel = try XCTUnwrap(property(named: "viewModel", in: productForm))
        let injectedUploader: MockProductImageUploader = try XCTUnwrap(property(named: "productImageUploader", in: productForm))
        let currency: String = try XCTUnwrap(property(named: "currency", in: productForm))
        let isAIContent: Bool = try XCTUnwrap(property(named: "isAIContent", in: productForm))

        // Then
        guard case .add = viewModel.formType else {
            return XCTFail("Expected an add product form")
        }
        XCTAssertTrue(injectedUploader === productImageUploader)
        XCTAssertEqual(currency, currencySettings.symbol(from: currencySettings.currencyCode))
        XCTAssertTrue(isAIContent)
    }

    func test_factory_selects_store_renderer_for_existing_products_when_flag_is_enabled() throws {
        let featureFlagService = MockFeatureFlagService()
        let cases: [(ProductFormType, Bool, Bool)] = [
            (.edit, true, true), (.readonly, true, true), (.add, true, false),
            (.edit, false, false), (.readonly, false, false), (.add, false, false)
        ]

        for (formType, isFlagEnabled, expectedStoreRenderer) in cases {
            // Given
            featureFlagService.isFeatureFlagEnabledReturnValue[.storeDesignSystem] = isFlagEnabled

            // When
            let controller = ProductDetailsFactory.productDetails(product: .fake(),
                                                                  presentationStyle: .navigationStack,
                                                                  formType: formType,
                                                                  featureFlagService: featureFlagService,
                                                                  onDuplicateCompletion: { _, _ in })

            // Then
            let usesStoreRenderer: Bool = try XCTUnwrap(property(named: "usesStoreRenderer", in: controller))
            XCTAssertEqual(usesStoreRenderer, expectedStoreRenderer, "Form type \(formType), flag enabled \(isFlagEnabled)")
        }
    }

    func test_factory_forwards_product_creation_callback_with_share_eligibility() throws {
        // Given
        let product = Product.fake()
        let createdProduct = Product.fake().copy(productID: 123)
        var receivedProduct: Product?
        var receivedCanShareProduct: Bool?

        // When
        let viewController = ProductDetailsFactory.productDetails(product: product,
                                                                  presentationStyle: .navigationStack,
                                                                  formType: .add,
                                                                  onProductCreated: { product, canShareProduct in
                                                                      receivedProduct = product
                                                                      receivedCanShareProduct = canShareProduct
                                                                  },
                                                                  onDuplicateCompletion: { _, _ in })
        let productForm = try XCTUnwrap(viewController as? ProductFormViewController<ProductFormViewModel>)
        let viewModel: ProductFormViewModel = try XCTUnwrap(property(named: "viewModel", in: productForm))
        viewModel.onProductCreated(createdProduct)

        // Then
        XCTAssertEqual(receivedProduct?.productID, createdProduct.productID)
        XCTAssertEqual(receivedCanShareProduct, viewModel.canShareProduct())
    }

    func test_factory_forwards_product_deletion_callback() throws {
        // Given
        var deletionCallCount = 0

        // When
        let viewController = ProductDetailsFactory.productDetails(product: .fake(),
                                                                  presentationStyle: .navigationStack,
                                                                  formType: .edit,
                                                                  onDeleteCompletion: {
                                                                      deletionCallCount += 1
                                                                  },
                                                                  onDuplicateCompletion: { _, _ in })
        let productForm = try XCTUnwrap(viewController as? ProductFormViewController<ProductFormViewModel>)
        let onDeleteCompletion: () -> Void = try XCTUnwrap(property(named: "onDeleteCompletion", in: productForm))
        onDeleteCompletion()

        // Then
        XCTAssertEqual(deletionCallCount, 1)
    }

    private func property<T>(named name: String, in object: Any) -> T? {
        Mirror(reflecting: object).children.first { $0.label == name }?.value as? T
    }
}
