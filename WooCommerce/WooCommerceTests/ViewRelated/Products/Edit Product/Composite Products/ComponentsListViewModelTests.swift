import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ComponentsListViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 12345

    func test_view_model_prefills_component_data_correctly() throws {
        // Given
        let compositeComponent = ProductCompositeComponent.fake().copy(componentID: "1",
                                                                       title: "Camera Body",
                                                                       description: "Choose between the Nikon D600 or the powerful Canon EOS 5D Mark IV.",
                                                                       imageURL: "https://woocommerce.com/woo.jpg",
                                                                       optionType: .productIDs)

        // When
        let viewModel = ComponentsListViewModel(siteID: sampleSiteID, components: [compositeComponent])
        let component = try XCTUnwrap(viewModel.components.first)

        // Then
        XCTAssertEqual(component.id, compositeComponent.componentID)
        XCTAssertEqual(component.title, compositeComponent.title)
        XCTAssertEqual(component.description, compositeComponent.description)
        XCTAssertEqual(component.imageURL?.absoluteString, compositeComponent.imageURL)
        XCTAssertEqual(component.optionType, compositeComponent.optionType)
    }
}
