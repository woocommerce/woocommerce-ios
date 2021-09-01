import XCTest
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
        let item = try makeItem()
        let viewModel = WhatsNewViewModel(items: [item], onDismiss: {})

        // Assert
        XCTAssertEqual(viewModel.items.count, 1)
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

    func makeItem() throws -> ReportItem {
        ReportItem(title: "foo", subtitle: "bar", icon: .remote(URL(string: "https://s0.wordpress.com/i/store/mobile/plans-premium.png")!))
    }
}
