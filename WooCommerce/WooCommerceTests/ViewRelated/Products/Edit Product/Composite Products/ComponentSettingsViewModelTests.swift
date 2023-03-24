import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ComponentSettingsViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 12345

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

    func test_view_model_prefills_expected_data_from_component_list() {
        // Given
        let component = ComponentsListViewModel.Component(id: "1",
                                                          title: "Camera Body",
                                                          imageURL: URL(string: "https://woocommerce.com/woo.jpg"),
                                                          description: "Choose between the Nikon D600 or the powerful Canon EOS 5D Mark IV.",
                                                          optionType: .productIDs,
                                                          optionIDs: [],
                                                          defaultOptionID: "")

        // When
        let viewModel = ComponentSettingsViewModel(siteID: sampleSiteID, component: component)

        // Then
        XCTAssertEqual(viewModel.componentTitle, component.title)
        XCTAssertEqual(viewModel.description, component.description)
        XCTAssertEqual(viewModel.imageURL, component.imageURL)
        XCTAssertEqual(viewModel.optionsType, component.optionType.description)
        XCTAssertEqual(viewModel.options, [])
        XCTAssertEqual(viewModel.defaultOptionTitle,
                       NSLocalizedString("None", comment: "Label when there is no default option for a component in a composite product"))
    }
}
