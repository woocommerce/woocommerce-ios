import Foundation
import Testing
import Yosemite
import Fakes
import YosemiteTestHelpers
import ViewControllerPresentationSpy
import UIKit
@testable import WooCommerce

@MainActor
struct RefundDetailsViewModelTests {
    private let siteID: Int64 = 123
    private let productID: Int64 = 1
    private let variationID: Int64 = 10

    @Test func test_totals_when_refund_amounts_are_negative_then_displays_positive_totals() {
        // Given
        let item = OrderItemRefund.fake().copy(subtotal: "-20", subtotalTax: "-2")
        let viewModel = RefundDetailsViewModel(order: Order.fake().copy(currency: "USD"),
                                               refund: Refund.fake().copy(items: [item]),
                                               storageManager: MockStorageManager())

        // When
        let subtotal = viewModel.itemSubtotal
        let tax = viewModel.taxSubtotal
        let total = viewModel.productsRefund

        // Then
        #expect(subtotal == viewModel.currencyFormatter.formatAmount("20", with: "USD"))
        #expect(tax == viewModel.currencyFormatter.formatAmount("2", with: "USD"))
        #expect(total == viewModel.currencyFormatter.formatAmount("22", with: "USD"))
    }

    @Test func test_selecting_refunded_product_when_row_is_tapped_then_presents_product_loader() throws {
        // Given
        let presentationVerifier = PresentationVerifier()
        let item = OrderItemRefund.fake().copy(productID: productID)
        let viewModel = RefundDetailsViewModel(order: Order.fake().copy(siteID: siteID),
                                               refund: Refund.fake().copy(siteID: siteID, items: [item]),
                                               storageManager: MockStorageManager())
        let viewController = UIViewController()
        viewModel.reloadSections()

        // When
        viewModel.tableView(UITableView(), in: viewController, didSelectRowAt: IndexPath(row: 0, section: 0))

        // Then
        let navigationController: UINavigationController? = presentationVerifier.verify(animated: true,
                                                                                        presentingViewController: viewController)
        let presentedViewController = try #require(navigationController?.topViewController)
        #expect(presentedViewController is ProductLoaderViewController)
    }

    @Test func dataSource_uses_the_injected_storageManager_to_resolve_images() {
        // Given
        let storageManager = MockStorageManager()
        let variation = ProductVariation.fake().copy(siteID: siteID,
                                                     productID: productID,
                                                     productVariationID: variationID,
                                                     image: ProductImage.fake().copy(src: "https://example.com/variation.jpg"))
        insert(variation: variation, into: storageManager)
        let refundedItem = OrderItemRefund.fake().copy(productID: productID, variationID: variationID)
        let viewModel = RefundDetailsViewModel(order: Order.fake().copy(siteID: siteID),
                                               refund: Refund.fake().copy(items: [refundedItem]),
                                               storageManager: storageManager)

        // When
        viewModel.configureResultsControllers(onReload: {})

        // Then
        #expect(viewModel.dataSource.imageURL(for: refundedItem) == URL(string: "https://example.com/variation.jpg"))
    }
}

private extension RefundDetailsViewModelTests {
    /// `update(with:)` only copies attributes, so the image relationship is attached manually.
    func insert(variation: ProductVariation, into storageManager: MockStorageManager) {
        let storageVariation = storageManager.viewStorage.insertNewObject(ofType: StorageProductVariation.self)
        storageVariation.update(with: variation)
        if let image = variation.image {
            let storageImage = storageManager.viewStorage.insertNewObject(ofType: StorageProductImage.self)
            storageImage.update(with: image)
            storageVariation.image = storageImage
        }
    }
}
