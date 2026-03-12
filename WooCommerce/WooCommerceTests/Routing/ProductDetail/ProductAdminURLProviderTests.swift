@testable import WooCommerce
import Testing
import Yosemite

final class ProductAdminURLProviderTests {

    private let storeURL = "https://nicestore.com"
    private let productID: Int64 = 1234567
    private lazy var aSite = Site.fake().copy(url: storeURL)

    @Test
    func test_editURL_for_booking_product_uses_next_admin_services_path() throws {
        // Given
        let bookingProduct = Product.fake().copy(productID: productID, productTypeKey: "bookable-service")

        // When
        let url = try #require(ProductAdminURLProvider.editURL(for: bookingProduct, site: aSite))

        // Then
        #expect(url.absoluteString ==
                "\(storeURL)/wp-admin/admin.php?page=next-admin&p=/woocommerce/services/edit/\(productID)")
    }

    @Test
    func test_editURL_for_legacy_booking_product_uses_wp_admin_post_path() throws {
        // Given
        let simpleProduct = Product.fake().copy(productID: productID, productTypeKey: "booking")

        // When
        let url = try #require(ProductAdminURLProvider.editURL(for: simpleProduct, site: aSite))

        // Then
        #expect(url.absoluteString ==
                "\(storeURL)/wp-admin/post.php?post=\(productID)&action=edit")
    }
}
