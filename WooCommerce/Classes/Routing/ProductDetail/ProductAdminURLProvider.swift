import Yosemite
import Foundation

/// Builds canonical admin edit URLs for products.
enum ProductAdminURLProvider {

    static func editURL(for product: Product, site: Site?) -> URL? {
        guard let base = site?.adminURLWithFallback() else { return nil }

        /// Only use CIAB next admin URL for new booking type
        /// Otherwise, use the default wp-admin URL
        guard product.productType == .booking else {
            return base.appending(path: "post.php", directoryHint: .notDirectory)
                .appending(queryItems: [
                    URLQueryItem(name: "post", value: product.productID.description),
                    URLQueryItem(name: "action", value: "edit")
                ])
        }

        let adminBase = base.appending(path: "admin.php", directoryHint: .notDirectory)

        var components = URLComponents(url: adminBase, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "page", value: "next-admin"),
            URLQueryItem(name: "p", value: "/woocommerce/services/edit/\(product.productID)")
        ]

        return components.url
    }
}
