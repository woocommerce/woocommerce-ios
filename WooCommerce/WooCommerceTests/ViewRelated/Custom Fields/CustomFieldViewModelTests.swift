import XCTest
import Yosemite

@testable import WooCommerce

class CustomFieldViewModelTests: XCTestCase {

    func test_view_model_inits_with_expected_values() throws {
        // Given
        let url = URL(string: "https://woocommerce.com/")
        let viewModel = CustomFieldViewModel(id: 1, title: "First Metadata", content: "First Content", contentURL: url)

        // Then
        XCTAssertEqual(viewModel.id, 1)
        XCTAssertEqual(viewModel.title, "First Metadata")
        XCTAssertEqual(viewModel.content, "First Content")
        XCTAssertEqual(viewModel.contentURL, url)
    }

    func test_init_with_MetaData_creates_contentURL_from_metadata_value() throws {
        // Given
        let urlString = "https://woocommerce.com/"
        let metadata = MetaData(metadataID: 0, key: "URL Metadata", value: urlString)

        // When
        let viewModel = CustomFieldViewModel(metadata: metadata)

        // Then
        XCTAssertEqual(viewModel.contentURL, URL(string: urlString))
    }

}
