import XCTest
@testable import WooCommerce
@testable import Yosemite

final class GenerateAllVariationsUseCaseTests: XCTestCase {
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

        let useCase = GenerateAllVariationsUseCase(stores: stores)

        // When
        let error = waitFor { promise in
            useCase.generateAllVariations(for: product) { state in
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

        let useCase = GenerateAllVariationsUseCase(stores: stores)

        // When
        let succeeded = waitFor { promise in
            useCase.generateAllVariations(for: product) { state in
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

    func test_generating_no_variations_sends_completed_state() {
        // Given
        let product = Product.fake().copy(attributes: [ProductAttribute.fake().copy(attributeID: 1, name: "Size", options: ["XS"])])
        let stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case .synchronizeAllProductVariations(_, _, let onCompletion):
                let variation = ProductVariation.fake().copy(attributes: [.init(id: 1, name: "Size", option: "XS")])
                onCompletion(.success([variation]))
            case .createProductVariations(_, _, _, let onCompletion):
                onCompletion(.success([]))
            default:
                break
            }
        }

        let useCase = GenerateAllVariationsUseCase(stores: stores)

        // When
        let variationsGenerated = waitFor { promise in
            useCase.generateAllVariations(for: product) { state in
                if case .finished(let variationsGenerated, _) = state {
                    promise(variationsGenerated)
                }
            }
        }

        // Then
        XCTAssertFalse(variationsGenerated)
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

        let useCase = GenerateAllVariationsUseCase(stores: stores)

        // When
        let canceled = waitFor { promise in
            useCase.generateAllVariations(for: product) { state in
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

    func test_failing_to_fetch_variations_sends_error_state() {
        // Given
        let product = Product.fake().copy(attributes: [
            ProductAttribute.fake().copy(attributeID: 1, name: "Size", options: ["XS", "S", "M", "L", "XL"]),
            ProductAttribute.fake().copy(attributeID: 2, name: "Color", options: ["Red", "Green", "Blue", "White", "Black"]),
        ])

        let stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case .synchronizeAllProductVariations(_, _, let onCompletion):
                onCompletion(.failure(NSError(domain: "", code: 0)))
            default:
                break
            }
        }

        let useCase = GenerateAllVariationsUseCase(stores: stores)

        // When
        let error = waitFor { promise in
            useCase.generateAllVariations(for: product) { state in
                if case .error(let error) = state {
                    promise(error)
                }
            }
        }

        // Then
        XCTAssertEqual(error, .unableToFetchVariations)
    }

    func test_failing_to_create_variations_sends_error_state() {
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
                onCompletion(.failure(NSError(domain: "", code: 0)))
            default:
                break
            }
        }

        let useCase = GenerateAllVariationsUseCase(stores: stores)

        // When
        let error = waitFor { promise in
            useCase.generateAllVariations(for: product) { state in
                if case let .confirmation(_, onCompletion) = state {
                    onCompletion(true)
                }
                if case .error(let error) = state {
                    promise(error)
                }
            }
        }

        // Then
        XCTAssertEqual(error, .unableToCreateVariations)
    }
}
