import XCTest
import Yosemite

@testable import WooCommerce

class CustomFieldsViewModelTests: XCTestCase {

    func test_view_model_inits_with_expected_values() throws {
        // Given
        let url = URL(string: "https://woocommerce.com/")
        let viewModel = CustomFieldsViewModel(id: 1, title: "First Metadata", content: "First Content", contentURL: url)

        // Then
        XCTAssertEqual(viewModel.id, 1)
        XCTAssertEqual(viewModel.title, "First Metadata")
        XCTAssertEqual(viewModel.content, "First Content")
        XCTAssertEqual(viewModel.contentURL, url)
    }

    func test_init_with_MetaData_strips_HTML_from_metadata_value() throws {
        // Given
        let metadata = MetaData(metadataID: 0, key: "HTML Metadata", value: "<strong>Fancy</strong> <a href=\"http://\">Metadata</a>")

        // When
        let viewModel = CustomFieldsViewModel(metadata: metadata)

        // Then
        XCTAssertEqual(viewModel.content, "Fancy Metadata")
    }

    func test_init_with_MetaData_creates_contentURL_from_metadata_value() throws {
        // Given
        let urlString = "https://woocommerce.com/"
        let metadata = MetaData(metadataID: 0, key: "URL Metadata", value: urlString)

        // When
        let viewModel = CustomFieldsViewModel(metadata: metadata)

        // Then
        XCTAssertEqual(viewModel.contentURL, URL(string: urlString))
    }

}
