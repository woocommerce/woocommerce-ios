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

    func test_noOrdersAvailableConfig_when_store_previously_qualified_for_test_order_then_uses_first_order_empty_state() throws {
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
        let config = viewController.noOrdersAvailableConfig()

        // Then
        guard case let .withLink(message, image, details, linkTitle, linkURL, _) = config else {
            XCTFail("Expected the first-order empty state link config.")
            return
        }
        XCTAssertEqual(message.string, "Waiting for your first order")
        XCTAssertEqual(image, .boxesImage)
        XCTAssertEqual(details, "Explore how you can increase your store sales.")
        XCTAssertEqual(linkTitle, "Learn more")
        XCTAssertEqual(linkURL, WooConstants.URLs.blog.asURL())
    }
}
