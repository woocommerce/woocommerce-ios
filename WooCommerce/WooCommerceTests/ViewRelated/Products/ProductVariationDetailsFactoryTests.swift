import XCTest
import Yosemite
import Fakes
import WooFoundation
@testable import WooCommerce

@MainActor
final class ProductVariationDetailsFactoryTests: XCTestCase {
    func test_factory_creates_product_variation_form() throws {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let parentProduct = Product.fake()

        // Action
        let viewController = waitFor { promise in
            ProductVariationDetailsFactory.productVariationDetails(productVariation: productVariation,
                                                                   parentProduct: parentProduct,
                                                                   presentationStyle: .navigationStack,
                                                                   forceReadOnly: false) { viewController in
                                                    promise(viewController)
            }
        }

        // Assert
        XCTAssertTrue(viewController is ProductFormViewController<ProductVariationFormViewModel>)
    }

    func test_factory_names_the_variation_only_from_attributes_used_for_variations() throws {
        // Given
        let productVariation = ProductVariation.fake().copy(attributes: [.init(id: 1, name: "Color", option: "Red")])
        let parentProduct = Product.fake().copy(attributes: [
            ProductAttribute.fake().copy(attributeID: 1, name: "Color", variation: true, options: ["Red", "Blue"]),
            ProductAttribute.fake().copy(attributeID: 0, name: "Material", variation: false, options: ["Cotton"])
        ])

        // When
        let viewController = waitFor { promise in
            ProductVariationDetailsFactory.productVariationDetails(productVariation: productVariation,
                                                                   parentProduct: parentProduct,
                                                                   presentationStyle: .navigationStack,
                                                                   forceReadOnly: false) { viewController in
                                                    promise(viewController)
            }
        }
        viewController.loadViewIfNeeded()

        // Then
        XCTAssertEqual(viewController.navigationItem.backButtonTitle, "Red")
    }

    func test_factory_configures_requested_form_type_event_logger_and_injected_dependencies() throws {
        // Given
        let productVariation = ProductVariation.fake()
        let parentProduct = Product.fake()
        let eventLogger = MockProductFormEventLogger()
        let currencySettings = CurrencySettings(currencyCode: .EUR,
                                                currencyPosition: .right,
                                                thousandSeparator: ",",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 2)
        let productImageUploader = MockProductImageUploader()

        // When
        let viewController = try makeViewController(productVariation: productVariation,
                                                    parentProduct: parentProduct,
                                                    formType: .readonly,
                                                    eventLogger: eventLogger,
                                                    currencySettings: currencySettings,
                                                    productImageUploader: productImageUploader)
        let productForm = try XCTUnwrap(viewController as? ProductFormViewController<ProductVariationFormViewModel>)
        let viewModel: ProductVariationFormViewModel = try XCTUnwrap(property(named: "viewModel", in: productForm))
        let injectedEventLogger: MockProductFormEventLogger = try XCTUnwrap(property(named: "eventLogger", in: productForm))
        let injectedUploader: MockProductImageUploader = try XCTUnwrap(property(named: "productImageUploader", in: productForm))
        let currency: String = try XCTUnwrap(property(named: "currency", in: productForm))

        // Then
        guard case .readonly = viewModel.formType else {
            return XCTFail("Expected a read-only variation form")
        }
        XCTAssertTrue(injectedEventLogger === eventLogger)
        XCTAssertTrue(injectedUploader === productImageUploader)
        XCTAssertEqual(currency, currencySettings.symbol(from: currencySettings.currencyCode))
    }

    func test_factory_forwards_variation_deletion_callback() throws {
        // Given
        let productVariation = ProductVariation.fake().copy(productVariationID: 123)
        var deletedVariation: ProductVariation?

        // When
        let viewController = try makeViewController(productVariation: productVariation,
                                                    onVariationDeletion: { variation in
                                                        deletedVariation = variation
                                                    })
        let productForm = try XCTUnwrap(viewController as? ProductFormViewController<ProductVariationFormViewModel>)
        let viewModel: ProductVariationFormViewModel = try XCTUnwrap(property(named: "viewModel", in: productForm))
        viewModel.onVariationDeletion?(productVariation)

        // Then
        XCTAssertEqual(deletedVariation?.productVariationID, productVariation.productVariationID)
    }

    private func makeViewController(productVariation: ProductVariation,
                                    parentProduct: Product = .fake(),
                                    formType: ProductFormType = .edit,
                                    eventLogger: ProductFormEventLoggerProtocol = MockProductFormEventLogger(),
                                    currencySettings: CurrencySettings = .init(),
                                    productImageUploader: ProductImageUploaderProtocol = MockProductImageUploader(),
                                    onVariationDeletion: @escaping (ProductVariation) -> Void = { _ in }) throws -> UIViewController {
        var result: UIViewController?
        ProductVariationDetailsFactory.productVariationDetails(productVariation: productVariation,
                                                                parentProduct: parentProduct,
                                                                presentationStyle: .navigationStack,
                                                                formType: formType,
                                                                eventLogger: eventLogger,
                                                                currencySettings: currencySettings,
                                                                productImageUploader: productImageUploader,
                                                                onVariationDeletion: onVariationDeletion) { viewController in
            result = viewController
        }
        return try XCTUnwrap(result)
    }

    private func property<T>(named name: String, in object: Any) -> T? {
        Mirror(reflecting: object).children.first { $0.label == name }?.value as? T
    }
}

private final class MockProductFormEventLogger: ProductFormEventLoggerProtocol {
    func logDescriptionTapped() {}
    func logImageTapped() {}
    func logPriceSettingsTapped() {}
    func logInventorySettingsTapped() {}
    func logShippingSettingsTapped() {}
    func logUpdateButtonTapped() {}
    func logQuantityRulesTapped() {}
    func logSubscriptionsFreeTrialTapped() {}
    func logSubscriptionsExpirationDateTapped() {}
    func logQuantityRulesDoneButtonTapped(hasUnsavedChanges: Bool) {}
}
