import XCTest
@testable import WooCommerce
@testable import Yosemite

final class EditAttributesViewModelTests: XCTestCase {

    func test_done_button_is_visible_when_allowing_variation_creation() {
        // Given, Then
        let viewModel = EditAttributesViewModel(product: .init(), allowVariationCreation: true)

        // Then
        XCTAssertTrue(viewModel.showDoneButton)
    }

    func test_done_button_is_not_visible_when_not_allowing_variation_creation() {
        // Given, Then
        let viewModel = EditAttributesViewModel(product: .init(), allowVariationCreation: false)

        // Then
        XCTAssertFalse(viewModel.showDoneButton)
    }

    func test_product_attributes_are_correctly_converted_into_view_models() {
        // Given
        let attribute = sampleAttribute(name: "attr", options: ["Option 1", "Option 2"])
        let product = Product().copy(attributes: [attribute])

        // When
        let viewModel = EditAttributesViewModel(product: product, allowVariationCreation: false)

        // Then
        let expectedVM = ImageAndTitleAndTextTableViewCell.ViewModel(title: "attr",
                                                                     text: "Option 1, Option 2",
                                                                     numberOfLinesForTitle: 0,
                                                                     numberOfLinesForText: 0)
        XCTAssertEqual(viewModel.attributes, [expectedVM])
    }

    func test_product_attributes_are_recreated_after_updating_the_product() {
        // Given
        let attribute = sampleAttribute(name: "attr", options: ["Option 1", "Option 2"])
        let attribute2 = sampleAttribute(name: "attr-2", options: ["Option 3", "Option 4"])
        let product = Product().copy(attributes: [attribute])
        let product2 = product.copy(attributes: [attribute, attribute2])

        // When
        let viewModel = EditAttributesViewModel(product: product, allowVariationCreation: false)
        viewModel.updateProduct(product2)

        // Then
        let expectedVM = ImageAndTitleAndTextTableViewCell.ViewModel(title: "attr",
                                                                     text: "Option 1, Option 2",
                                                                     numberOfLinesForTitle: 0,
                                                                     numberOfLinesForText: 0)
        let expectedVM2 = ImageAndTitleAndTextTableViewCell.ViewModel(title: "attr-2",
                                                                      text: "Option 3, Option 4",
                                                                      numberOfLinesForTitle: 0,
                                                                      numberOfLinesForText: 0)
        XCTAssertEqual(viewModel.attributes, [expectedVM, expectedVM2])
    }

    func test_create_variations_is_invoked_with_correct_parameters() {
        // Given
        let attribute = sampleAttribute(attributeID: 0, name: "attr", options: ["Option 1", "Option 2"])
        let attribute2 = sampleAttribute(attributeID: 1, name: "attr-2", options: ["Option 3", "Option 4"])
        let product = Product().copy(attributes: [attribute, attribute2])

        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = EditAttributesViewModel(product: product, allowVariationCreation: true, stores: mockStores)

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

            viewModel.generateVariation { _ in }
        }

        // Then
        let expectedAttributes = [
            ProductVariationAttribute(id: 0, name: "attr", option: ""),
            ProductVariationAttribute(id: 1, name: "attr-2", option: ""),
        ]
        let expectedVariation = CreateProductVariation(regularPrice: "", attributes: expectedAttributes)
        XCTAssertEqual(expectedVariation, variationSubmitted)
    }
}

private extension EditAttributesViewModelTests {
    func sampleAttribute(attributeID: Int64 = 1234, name: String, options: [String] = []) -> ProductAttribute {
        ProductAttribute(siteID: 123,
                         attributeID: attributeID,
                         name: name ,
                         position: 0,
                         visible: true,
                         variation: true,
                         options: options)
    }
}
