@testable import WooCommerce
import Testing
import Yosemite

final class ProductAdminURLProviderTests {

    private let storeURL = "https://nicestore.com"
    private let productID: Int64 = 1234567
    private lazy var aProduct = Product.fake().copy(productID: productID)
    private lazy var aSite = Site.fake().copy(url: storeURL)

    @Test
    func test_editURL_uses_services_path() throws {
        // Given / When
        let url = try #require(ProductAdminURLProvider.editURL(for: aProduct, site: aSite))

        // Then
        #expect(url.absoluteString ==
                "\(storeURL)/wp-admin?page=next-admin&p=/woocommerce/services/edit/\(productID)")
    }
}
