import XCTest
import Yosemite

@testable import WooCommerce

class CustomFieldViewModelTests: XCTestCase {

    func test_view_model_inits_with_expected_values() throws {
        // Given
        let url = URL(string: "https://woocommerce.com/")
        let viewModel = CustomFieldViewModel(fieldID: 1, key: "First Metadata", value: "First Content", valueURL: url)

        // Then
        XCTAssertEqual(viewModel.fieldID, 1)
        XCTAssertEqual(viewModel.key, "First Metadata")
        XCTAssertEqual(viewModel.value, "First Content")
        XCTAssertEqual(viewModel.valueURL, url)
    }

    func test_init_with_MetaData_creates_contentURL_from_metadata_value() throws {
        // Given
        let urlString = "https://woocommerce.com/"
        let metadata = MetaData(metadataID: 0, key: "URL Metadata", value: urlString)

        // When
        let viewModel = CustomFieldViewModel(metadata: metadata)

        // Then
        XCTAssertEqual(viewModel.valueURL, URL(string: urlString))
    }

    func test_when_isJson_called_then_return_correct_value() {
        let jsonField = CustomFieldViewModel(key: "key", value: "{\"key\":\"value\"}")
        XCTAssertTrue(jsonField.isJson)

        let nonJsonField = CustomFieldViewModel(key: "key", value: "value")
        XCTAssertFalse(nonJsonField.isJson)
    }
}
