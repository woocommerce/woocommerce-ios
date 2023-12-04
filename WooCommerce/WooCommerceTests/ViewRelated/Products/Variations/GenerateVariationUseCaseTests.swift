import XCTest
@testable import WooCommerce
@testable import Yosemite

final class GenerateVariationUseCaseTests: XCTestCase {
    func test_create_variations_is_invoked_with_correct_parameters_for_regular_variable_product() {
        // Given
        let attribute = sampleAttribute(attributeID: 0, name: "attr", options: ["Option 1", "Option 2"])
        let attribute2 = sampleAttribute(attributeID: 1, name: "attr-2", options: ["Option 3", "Option 4"])
        let attribute3 = sampleNonVariationAttribute(name: "attr-extra", options: ["Option X", "Option Y"])
        let product = Product.fake().copy(attributes: [attribute, attribute2, attribute3])

        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let useCase = GenerateVariationUseCase(product: product, stores: mockStores)

        // When
        let variationSubmitted: CreateProductVariation = waitFor { promise in
            mockStores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
               switch action {
               case let .createProductVariation(_, _, newVariation, _):
                promise(newVariation)
               default:
                   break
               }
            }

            useCase.generateVariation { _ in }
        }

        // Then
        let expectedAttributes = [
            ProductVariationAttribute(id: 0, name: "attr", option: ""),
            ProductVariationAttribute(id: 1, name: "attr-2", option: ""),
        ]
        let expectedVariation = CreateProductVariation(regularPrice: "",
                                                       salePrice: "",
                                                       attributes: expectedAttributes,
                                                       description: "",
                                                       image: nil,
                                                       subscription: nil)
        XCTAssertEqual(expectedVariation, variationSubmitted)
    }

    func test_create_variations_is_invoked_with_correct_parameters_for_subscription_variable_product() {
        // Given
        let attribute = sampleAttribute(attributeID: 0, name: "attr", options: ["Option 1", "Option 2"])
        let attribute2 = sampleAttribute(attributeID: 1, name: "attr-2", options: ["Option 3", "Option 4"])
        let attribute3 = sampleNonVariationAttribute(name: "attr-extra", options: ["Option X", "Option Y"])
        let product = Product.fake().copy(productTypeKey: ProductType.variableSubscription.rawValue,
                                          attributes: [attribute, attribute2, attribute3])

        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let useCase = GenerateVariationUseCase(product: product, stores: mockStores)

        // When
        let variationSubmitted: CreateProductVariation = waitFor { promise in
            mockStores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
               switch action {
               case let .createProductVariation(_, _, newVariation, _):
                promise(newVariation)
               default:
                   break
               }
            }

            useCase.generateVariation { _ in }
        }

        // Then
        let expectedAttributes = [
            ProductVariationAttribute(id: 0, name: "attr", option: ""),
            ProductVariationAttribute(id: 1, name: "attr-2", option: ""),
        ]
        let expectedVariation = CreateProductVariation(regularPrice: "",
                                                       salePrice: "",
                                                       attributes: expectedAttributes,
                                                       description: "",
                                                       image: nil,
                                                       subscription: .empty)
        XCTAssertEqual(expectedVariation, variationSubmitted)
    }

    func test_create_variations_returns_variation_and_updated_product_variations_array() throws {
        // Given
        let attribute = sampleAttribute(attributeID: 0, name: "attr", options: ["Option 1", "Option 2"])
        let attribute2 = sampleAttribute(attributeID: 1, name: "attr-2", options: ["Option 3", "Option 4"])
        let product = Product.fake().copy(attributes: [attribute, attribute2])
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        mockStores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .createProductVariation(_, _, _, onCompletion):
                onCompletion(.success(MockProductVariation().productVariation()))
            default:
                break
            }
        }

        let useCase = GenerateVariationUseCase(product: product, stores: mockStores)

        // When
        let result: Result<(Product, ProductVariation), Error> = waitFor { promise in
            useCase.generateVariation { result in
                promise(result)
            }
        }

        // Then
        let (updatedProduct, newVariation) = try XCTUnwrap(result.get())
        let expectedVariationID = MockProductVariation().productVariation().productVariationID
        XCTAssertEqual(updatedProduct.variations, [expectedVariationID])
        XCTAssertEqual(newVariation.productVariationID, expectedVariationID)
    }
}

// MARK: Helper
private extension GenerateVariationUseCaseTests {
    func sampleAttribute(attributeID: Int64 = 1234, name: String, options: [String] = []) -> ProductAttribute {
        ProductAttribute(siteID: 123,
                         attributeID: attributeID,
                         name: name,
                         position: 0,
                         visible: true,
                         variation: true,
                         options: options)
    }

    func sampleNonVariationAttribute(attributeID: Int64 = 9999, name: String, options: [String] = []) -> ProductAttribute {
        ProductAttribute(siteID: 123,
                         attributeID: attributeID,
                         name: name,
                         position: 0,
                         visible: true,
                         variation: false,
                         options: options)
    }
}
