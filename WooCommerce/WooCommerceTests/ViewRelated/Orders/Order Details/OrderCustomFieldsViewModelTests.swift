import XCTest
import Yosemite

@testable import WooCommerce

class OrderCustomFieldsViewModelTests: XCTestCase {

    func test_view_model_inits_with_expected_values() throws {
        // Given
        let url = URL(string: "https://woocommerce.com/")
        let viewModel = OrderCustomFieldsViewModel(id: 1, title: "First Metadata", content: "First Content", contentURL: url)

        // Then
        XCTAssertEqual(viewModel.id, 1)
        XCTAssertEqual(viewModel.title, "First Metadata")
        XCTAssertEqual(viewModel.content, "First Content")
        XCTAssertEqual(viewModel.contentURL, url)
    }

    func test_init_with_OrderMetaData_strips_HTML_from_metadata_value() throws {
        // Given
        let metadata = OrderMetaData(metadataID: 0, key: "HTML Metadata", value: "<strong>Fancy</strong> <a href=\"http://\">Metadata</a>")

        // When
        let viewModel = OrderCustomFieldsViewModel(metadata: metadata)

        // Then
        XCTAssertEqual(viewModel.content, "Fancy Metadata")
    }

    func test_init_with_OrderMetaData_creates_contentURL_from_metadata_value() throws {
        // Given
        let urlString = "https://woocommerce.com/"
        let metadata = OrderMetaData(metadataID: 0, key: "URL Metadata", value: urlString)

        // When
        let viewModel = OrderCustomFieldsViewModel(metadata: metadata)

        // Then
        XCTAssertEqual(viewModel.contentURL, URL(string: urlString))
    }

}
