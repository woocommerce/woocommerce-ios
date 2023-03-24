import XCTest
@testable import WooCommerce

final class ComponentSettingsViewModelTests: XCTestCase {

    func test_component_image_and_description_visible_when_set() throws {
        // Given
        let imageURL = try XCTUnwrap(URL(string: "https://woocommerce.com/woo.jpg"))
        let viewModel = ComponentSettingsViewModel(title: "",
                                                   description: "Description",
                                                   imageURL: imageURL,
                                                   optionsType: "",
                                                   options: [],
                                                   defaultOptionTitle: "")

        // Then
        XCTAssertTrue(viewModel.shouldShowDescription)
        XCTAssertTrue(viewModel.shouldShowImage)
    }

    func test_component_image_and_description_hidden_when_not_set() {
        // Given
        let viewModel = ComponentSettingsViewModel(title: "", description: "", imageURL: nil, optionsType: "", options: [], defaultOptionTitle: "")

        // Then
        XCTAssertFalse(viewModel.shouldShowDescription)
        XCTAssertFalse(viewModel.shouldShowImage)
    }
}
