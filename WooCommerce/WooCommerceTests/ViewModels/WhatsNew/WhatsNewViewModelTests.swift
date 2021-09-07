import XCTest
import Yosemite
@testable import WooCommerce

class WhatsNewViewModelTests: XCTestCase {

    private var storesManager: MockStoresManager!

    override func setUp() {
        super.setUp()
        storesManager = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

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

    func test_on_appear_it_triggers_a_mark_as_displayed_action() throws {
        // Arrange
        let viewModel = WhatsNewViewModel(items: [], stores: storesManager, onDismiss: {})

        // Act
        viewModel.onAppear()

        // Assert
        XCTAssertEqual(storesManager.receivedActions.count, 1)
        XCTAssertTrue(storesManager.receivedActions.first is AnnouncementsAction)
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
