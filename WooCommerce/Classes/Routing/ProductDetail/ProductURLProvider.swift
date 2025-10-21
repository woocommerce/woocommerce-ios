import Yosemite
import Foundation

enum ProductURLProvider {
    static func editAdminURL(for product: Product, site: Site) -> URL? {
        guard let base = site.adminURLWithFallback() else { return nil }

        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "page", value: "next-admin"),
            URLQueryItem(name: "p", value: "/woocommerce/products/edit/\(product.productID)")
        ]

        return components.url
    }
}
