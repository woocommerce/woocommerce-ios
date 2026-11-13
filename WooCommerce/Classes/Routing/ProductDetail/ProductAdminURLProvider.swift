import Yosemite
import Foundation

/// Builds canonical admin edit URLs for products.
enum ProductAdminURLProvider {

    static func editURL(for product: Product, site: Site?) -> URL? {
        guard let base = site?.adminURLWithFallback() else { return nil }

        return base.appending(path: "post.php", directoryHint: .notDirectory)
            .appending(queryItems: [
                URLQueryItem(name: "post", value: product.productID.description),
                URLQueryItem(name: "action", value: "edit")
            ])
    }
}
