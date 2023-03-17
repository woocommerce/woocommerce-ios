import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ComponentsListViewModelTests: XCTestCase {

    func test_view_model_prefills_component_data_correctly() throws {
        // Given
        let compositeComponent = ProductCompositeComponent.fake().copy(componentID: "1", title: "Camera Body", imageURL: "https://woocommerce.com/woo.jpg")

        // When
        let viewModel = ComponentsListViewModel(components: [compositeComponent])
        let component = try XCTUnwrap(viewModel.components.first)

        // Then
        XCTAssertEqual(component.id, compositeComponent.componentID)
        XCTAssertEqual(component.title, compositeComponent.title)
        XCTAssertEqual(component.imageURL?.absoluteString, compositeComponent.imageURL)
    }
}
