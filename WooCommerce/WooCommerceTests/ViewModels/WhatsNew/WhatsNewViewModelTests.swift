import XCTest
import Yosemite
@testable import WooCommerce

/// Test cases for `WhatsNewViewModel`.
class WhatsNewViewModelTests: XCTestCase {

    func test_on_init_with_no_items_it_has_no_items() {
        // Arrange
        let viewModel = WhatsNewViewModel(items: [], onDismiss: {})

        // Assert
        XCTAssertTrue(viewModel.items.isEmpty)
    }

    func test_on_init_with_features_it_has_items() throws {
        // Arrange
        let viewModel = WhatsNewViewModel(items: [try makeFeature()], onDismiss: {})

        // Assert
        XCTAssertEqual(viewModel.items.first?.title, Expectations.Feature.title)
        XCTAssertEqual(viewModel.items.first?.subtitle, Expectations.Feature.subtitle)
        XCTAssertEqual(viewModel.items.first?.iconUrl, Expectations.Feature.iconUrl)
        XCTAssertEqual(viewModel.items.first?.iconBase64, Expectations.Feature.iconBase64)
    }

    func test_it_has_expected_localized_texts() {
        // Arrange
        let viewModel = WhatsNewViewModel(items: [], onDismiss: {})

        // Assert
        XCTAssertEqual(viewModel.title, Expectations.title)
        XCTAssertEqual(viewModel.ctaTitle, Expectations.ctaTitle)
    }
}

private extension WhatsNewViewModelTests {

    enum Expectations {
        enum Feature {
            static let title = "foo"
            static let subtitle = "bar"
            static let iconUrl = "https://s0.wordpress.com/i/store/mobile/plans-premium.png"
            static let iconBase64 = "test"
        }
        static let title = "What’s New in WooCommerce"
        static let ctaTitle = "Continue"
    }

    func makeFeature() throws -> Feature {
        let featureDictionary: [String: Any] = [
            "title": "foo",
            "subtitle": "bar",
            "iconBase64": "test",
            "iconUrl": "https://s0.wordpress.com/i/store/mobile/plans-premium.png"
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: featureDictionary)
        return try JSONDecoder().decode(Feature.self, from: jsonData)
    }
}
