import XCTest
import Fakes

@testable import WooCommerce
@testable import Yosemite

final class ProductFormActionsFactory_ProductCreationTests: XCTestCase {
    func test_product_type_is_editable_for_core_product_types() {
        // Product types supported in core.
        let coreProductTypes: [ProductType] = [.simple, .variable, .affiliate, .grouped]

        coreProductTypes.forEach { coreProductType in
            // Given
            let product = Product.fake().copy(productTypeKey: coreProductType.rawValue)
            let model = EditableProductModel(product: product)

            // When
            let actions = Fixtures.actionsFactory(product: model, formType: .add).settingsSectionActions()

            // Then
            XCTAssertTrue(actions.contains(.productType(editable: true)))
        }
    }

    func test_product_type_is_editable_for_woo_subscription_product_types() {
        // Product types supported by Woo Subscription plugin.
        let subscriptionProductTypes: [ProductType] = [.subscription, .variableSubscription]

        subscriptionProductTypes.forEach { type in
            // Given
            let product = Product.fake().copy(productTypeKey: type.rawValue)
            let model = EditableProductModel(product: product)

            // When
            let actions = Fixtures.actionsFactory(product: model, formType: .add).settingsSectionActions()

            // Then
            XCTAssertTrue(actions.contains(.productType(editable: true)))
        }
    }

    func test_product_type_is_not_editable_for_non_core_product_types() {
        // Product types supported in Woo extensions.
        let nonCoreProductTypes: [ProductType] = [.bundle, .composite, .custom("sub")]

        nonCoreProductTypes.forEach { nonCoreProductType in
            // Given
            let product = Product.fake().copy(productTypeKey: nonCoreProductType.rawValue)
            let model = EditableProductModel(product: product)

            // When
            let actions = Fixtures.actionsFactory(product: model, formType: .add).settingsSectionActions()

            // Then
            XCTAssertTrue(actions.contains(.productType(editable: false)))
        }
    }
}

private extension ProductFormActionsFactory_ProductCreationTests {
    enum Fixtures {
        // Factory with default feature settings.
        static func actionsFactory(product: EditableProductModel,
                                   formType: ProductFormType,
                                   addOnsFeatureEnabled: Bool = false,
                                   isLinkedProductsPromoEnabled: Bool = false,
                                   variationsPrice: ProductFormActionsFactory.VariationsPrice = .unknown) -> ProductFormActionsFactory {
            ProductFormActionsFactory(product: product,
                                      formType: formType,
                                      addOnsFeatureEnabled: addOnsFeatureEnabled,
                                      isLinkedProductsPromoEnabled: isLinkedProductsPromoEnabled,
                                      variationsPrice: variationsPrice)
        }
    }
}
