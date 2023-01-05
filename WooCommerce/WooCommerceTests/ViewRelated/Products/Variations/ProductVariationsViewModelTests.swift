import XCTest
@testable import WooCommerce
import Yosemite

final class ProductVariationsViewModelTests: XCTestCase {
    func test_empty_state_is_shown_when_product_does_not_have_variations_but_has_attributes() {
        // Given
        let attribute = ProductAttribute(siteID: 0, attributeID: 0, name: "attr", position: 0, visible: true, variation: true, options: [])
        let product = Product.fake().copy(attributes: [attribute], variations: [])
        let viewModel = ProductVariationsViewModel(formType: .edit)

        // Then
        let showEmptyState = viewModel.shouldShowEmptyState(for: product)

        // Then
        XCTAssertTrue(showEmptyState)
    }

    func test_empty_state_is_shown_when_product_does_not_have_attributes_but_has_variations() {
        // Given
        let product = Product.fake().copy(attributes: [], variations: [1, 2])
        let viewModel = ProductVariationsViewModel(formType: .edit)

        // Then
        let showEmptyState = viewModel.shouldShowEmptyState(for: product)

        // Then
        XCTAssertTrue(showEmptyState)
    }

    func test_empty_state_is_not_shown_when_product_has_attributes_and_variations() {
        // Given
        let attribute = ProductAttribute(siteID: 0, attributeID: 0, name: "attr", position: 0, visible: true, variation: true, options: [])
        let product = Product.fake().copy(attributes: [attribute], variations: [1, 2])
        let viewModel = ProductVariationsViewModel(formType: .edit)

        // Then
        let showEmptyState = viewModel.shouldShowEmptyState(for: product)

        // Then
        XCTAssertFalse(showEmptyState)
    }

    func test_attributes_guide_is_shown_when_product_does_not_have_attributes_or_variations() {
        // Given
        let product = Product.fake()
        let viewModel = ProductVariationsViewModel(formType: .edit)

        // Then
        let showAttributesGuide = viewModel.shouldShowAttributeGuide(for: product)

        // Then
        XCTAssertTrue(showAttributesGuide)
    }

    func test_attributes_guide_is_not_shown_when_product_has_attributes_but_no_variations() {
        let attribute = ProductAttribute(siteID: 0, attributeID: 0, name: "attr", position: 0, visible: true, variation: true, options: [])
        let product = Product.fake().copy(attributes: [attribute], variations: [])
        let viewModel = ProductVariationsViewModel(formType: .edit)

        // Then
        let showAttributesGuide = viewModel.shouldShowAttributeGuide(for: product)

        // Then
        XCTAssertFalse(showAttributesGuide)
    }

    func test_attributes_guide_is_shown_when_product_has_variations_but_no_attributes() {
        let product = Product.fake().copy(attributes: [], variations: [1, 2])
        let viewModel = ProductVariationsViewModel(formType: .edit)

        // Then
        let showAttributesGuide = viewModel.shouldShowAttributeGuide(for: product)

        // Then
        XCTAssertTrue(showAttributesGuide)
    }

    func test_formType_is_updated_to_edit_when_new_product_exists_remotely_and_formType_was_add() {
        // Given
        let product = Product.fake().copy(productID: 123)
        let viewModel = ProductVariationsViewModel(formType: .add)

        // When
        viewModel.updatedFormTypeIfNeeded(newProduct: product)

        // Then
        XCTAssertTrue(product.existsRemotely)
        XCTAssertEqual(viewModel.formType, .edit)
    }

    func test_formType_is_not_updated_when_new_product_does_not_exists_remotely_and_formType_was_add() {
        // Given
        let product = Product.fake().copy(productID: 0)
        let viewModel = ProductVariationsViewModel(formType: .add)

        // When
        viewModel.updatedFormTypeIfNeeded(newProduct: product)

        // Then
        XCTAssertFalse(product.existsRemotely)
        XCTAssertEqual(viewModel.formType, .add)
    }

    func test_formType_is_not_updated_when_new_product_exists_remotely_and_formType_was_read_only() {
        // Given
        let product = Product.fake().copy(productID: 123)
        let viewModel = ProductVariationsViewModel(formType: .readonly)

        // When
        viewModel.updatedFormTypeIfNeeded(newProduct: product)

        // Then
        XCTAssertTrue(product.existsRemotely)
        XCTAssertEqual(viewModel.formType, .readonly)
    }

    func test_trying_to_generate_more_than_100_variations_will_return_error() {
        // Given
        let product = Product.fake().copy(attributes: [
            ProductAttribute.fake().copy(attributeID: 1, name: "Size", options: ["XS", "S", "M", "L", "XL"]),
            ProductAttribute.fake().copy(attributeID: 2, name: "Color", options: ["Red", "Green", "Blue", "White", "Black"]),
            ProductAttribute.fake().copy(attributeID: 3, name: "Fabric", options: ["Cotton", "Nylon", "Polyester", "Silk", "Linen"]),
        ])

        let stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case .synchronizeAllProductVariations(_, _, let onCompletion):
                onCompletion(.success([]))
            default:
                break
            }
        }

        let viewModel = ProductVariationsViewModel(stores: stores, formType: .edit)

        // When
        let error = waitFor { promise in
            viewModel.generateAllVariations(for: product) { state in
                if case let .error(error) = state {
                    promise(error)
                }
            }
        }

        // Then
        XCTAssertEqual(error, .tooManyVariations(variationCount: 125))
    }

    func test_generating_less_than_100_variations_ask_for_confirmation_and_creates_variations() {
        // Given
        let product = Product.fake().copy(attributes: [
            ProductAttribute.fake().copy(attributeID: 1, name: "Size", options: ["XS", "S", "M", "L", "XL"]),
            ProductAttribute.fake().copy(attributeID: 2, name: "Color", options: ["Red", "Green", "Blue", "White", "Black"]),
        ])

        let stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case .synchronizeAllProductVariations(_, _, let onCompletion):
                onCompletion(.success([]))
            case .createProductVariations(_, _, _, let onCompletion):
                onCompletion(.success([]))
            default:
                break
            }
        }

        let viewModel = ProductVariationsViewModel(stores: stores, formType: .edit)

        // When
        let succeeded = waitFor { promise in
            viewModel.generateAllVariations(for: product) { state in
                if case let .confirmation(_, onCompletion) = state {
                    onCompletion(true)
                }
                if case .finished = state {
                    promise(true)
                }
            }
        }

        // Then
        XCTAssertTrue(succeeded)
    }

    func test_generating_less_than_100_variations_ask_for_confirmation_and_sends_cancel_state() {
        // Given
        let product = Product.fake().copy(attributes: [
            ProductAttribute.fake().copy(attributeID: 1, name: "Size", options: ["XS", "S", "M", "L", "XL"]),
            ProductAttribute.fake().copy(attributeID: 2, name: "Color", options: ["Red", "Green", "Blue", "White", "Black"]),
        ])

        let stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case .synchronizeAllProductVariations(_, _, let onCompletion):
                onCompletion(.success([]))
            case .createProductVariations(_, _, _, let onCompletion):
                onCompletion(.success([]))
            default:
                break
            }
        }

        let viewModel = ProductVariationsViewModel(stores: stores, formType: .edit)

        // When
        let canceled = waitFor { promise in
            viewModel.generateAllVariations(for: product) { state in
                if case let .confirmation(_, onCompletion) = state {
                    onCompletion(false)
                }
                if case .canceled = state {
                    promise(true)
                }
            }
        }

        // Then
        XCTAssertTrue(canceled)
    }
}
