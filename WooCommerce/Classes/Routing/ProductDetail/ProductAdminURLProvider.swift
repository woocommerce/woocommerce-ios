import Yosemite
import Foundation

/// Builds canonical admin edit URLs for products.
enum ProductAdminURLProvider {

    static func editURL(for product: Product, site: Site?) -> URL? {
        guard let base = site?.adminURLWithFallback() else { return nil }
        let adminBase = base.appending(path: "admin.php", directoryHint: .notDirectory)

        var components = URLComponents(url: adminBase, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "page", value: "next-admin"),
            URLQueryItem(name: "p", value: "/woocommerce/services/edit/\(product.productID)")
        ]

        return components.url
    }
}
