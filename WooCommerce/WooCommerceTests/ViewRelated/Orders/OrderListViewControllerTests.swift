import XCTest
import YosemiteTestHelpers
import Yosemite
import Storage
@testable import WooCommerce

final class OrderListViewControllerTests: XCTestCase {
    private var storageManager: MockStorageManager!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    func test_empty_state_when_store_previously_qualified_for_test_order_then_uses_first_order_empty_state() throws {
        // Given
        let siteID: Int64 = 123
        let site = Site.fake().copy(siteID: siteID, url: "https://example.com", visibility: .publicSite)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: site))
        storageManager.insertSampleProduct(readOnlyProduct: Product.fake().copy(siteID: siteID, statusKey: "publish"))
        storageManager.insertSamplePaymentGateway(readOnlyGateway: PaymentGateway.fake().copy(siteID: siteID, enabled: true))
        let viewModel = OrderListViewModel(siteID: siteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           filters: nil)
        let viewController = OrderListViewController(siteID: siteID,
                                                     title: "Orders",
                                                     viewModel: viewModel,
                                                     switchDetailsHandler: { _, _, _, _ in })

        // When
        viewController.loadViewIfNeeded()

        // Then
        let emptyStateViewController = try XCTUnwrap(viewController.children.compactMap { $0 as? EmptyStateViewController }.first)
        let mirror = try mirror(of: emptyStateViewController)

        XCTAssertEqual(mirror.messageLabel.attributedText, NSAttributedString(string: "Waiting for your first order"))
        XCTAssertEqual(mirror.imageView.image, .boxesImage)
        XCTAssertEqual(mirror.detailsLabel.text, "Explore how you can increase your store sales.")
        XCTAssertEqual(mirror.actionButton.titleLabel?.text, "Learn more")
    }
}

private extension OrderListViewControllerTests {
    struct EmptyStateViewControllerMirror {
        let messageLabel: UILabel
        let imageView: UIImageView
        let detailsLabel: UILabel
        let actionButton: UIButton
    }

    func mirror(of viewController: EmptyStateViewController) throws -> EmptyStateViewControllerMirror {
        let mirror = Mirror(reflecting: viewController)

        return EmptyStateViewControllerMirror(
            messageLabel: try XCTUnwrap(mirror.descendant("messageLabel") as? UILabel),
            imageView: try XCTUnwrap(mirror.descendant("imageView") as? UIImageView),
            detailsLabel: try XCTUnwrap(mirror.descendant("detailsLabel") as? UILabel),
            actionButton: try XCTUnwrap(mirror.descendant("actionButton") as? UIButton)
        )
    }
}
