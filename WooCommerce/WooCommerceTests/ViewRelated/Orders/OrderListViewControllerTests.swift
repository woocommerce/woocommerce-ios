import Testing
import UIKit
import YosemiteTestHelpers
import Yosemite
import Storage
@testable import WooCommerce

@MainActor
struct OrderListViewControllerTests {
    @Test func empty_state_when_store_previously_qualified_for_test_order_then_uses_first_order_empty_state() throws {
        // Given
        let siteID: Int64 = 123
        let site = Site.fake().copy(siteID: siteID, url: "https://example.com", visibility: .publicSite)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: site))
        let storageManager = MockStorageManager()
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
        let emptyStateViewController = try #require(
            viewController.children.compactMap { $0 as? EmptyStateViewController }.first
        )
        let mirror = try mirror(of: emptyStateViewController)

        #expect(mirror.messageLabel.attributedText == NSAttributedString(string: "Waiting for your first order"))
        #expect(mirror.imageView.image == .boxesImage)
        #expect(mirror.detailsLabel.text == "Explore how you can increase your store sales.")
        #expect(mirror.actionButton.titleLabel?.text == "Learn more")
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
            messageLabel: try #require(mirror.descendant("messageLabel") as? UILabel),
            imageView: try #require(mirror.descendant("imageView") as? UIImageView),
            detailsLabel: try #require(mirror.descendant("detailsLabel") as? UILabel),
            actionButton: try #require(mirror.descendant("actionButton") as? UIButton)
        )
    }
}
