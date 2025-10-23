@testable import WooCommerce
import Testing
import Yosemite

final class ProductAdminURLProviderTests {

    private let storeURL = "https://nicestore.com"
    private let productID: Int64 = 1234567
    private lazy var aProduct = Product.fake().copy(productID: productID)
    private lazy var aSite = Site.fake().copy(url: storeURL)

    @Test
    private func validateEditAdminURL() async throws {
        let url = try #require(ProductAdminURLProvider.editURL(for: aProduct, site: aSite))
        #expect(url.absoluteString ==
                "\(storeURL)/wp-admin?page=next-admin&p=/woocommerce/products/edit/\(productID)")
    }
}
