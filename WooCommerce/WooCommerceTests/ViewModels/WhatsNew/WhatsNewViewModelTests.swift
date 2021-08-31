import XCTest
import Yosemite
@testable import WooCommerce

class WhatsNewViewModelTests: XCTestCase {

    func test_on_init_with_no_items_it_has_no_items() {
        // Arrange, Act
        let viewModel = WhatsNewViewModel(items: [], onDismiss: {})

        // Assert
        XCTAssertTrue(viewModel.items.isEmpty)
    }

    func test_on_init_with_features_it_has_items() throws {
        // Arrange, Act
        let feature = try makeFeature()
        let viewModel = WhatsNewViewModel(items: [feature], onDismiss: {})

        // Assert
        XCTAssertEqual(viewModel.items.first?.title, feature.title)
        XCTAssertEqual(viewModel.items.first?.subtitle, feature.subtitle)
        XCTAssertEqual(viewModel.items.first?.iconUrl, feature.iconUrl)
        XCTAssertEqual(viewModel.items.first?.iconBase64, feature.iconBase64)
    }

    func test_it_has_expected_localized_texts() {
        // Arrange, Act
        let viewModel = WhatsNewViewModel(items: [], onDismiss: {})

        // Assert
        XCTAssertEqual(viewModel.title, Expectations.title)
        XCTAssertEqual(viewModel.ctaTitle, Expectations.ctaTitle)
    }
}

private extension WhatsNewViewModelTests {
    enum Expectations {
        static let title = "What’s New in WooCommerce"
        static let ctaTitle = "Continue"
    }

    func makeFeature() throws -> Feature {
        let jsonData = try JSONSerialization.data(withJSONObject: [
            "title": "foo",
            "subtitle": "bar",
            "iconBase64": "test",
            "iconUrl": "https://s0.wordpress.com/i/store/mobile/plans-premium.png"
        ])
        return try JSONDecoder().decode(Feature.self, from: jsonData)
    }
}
