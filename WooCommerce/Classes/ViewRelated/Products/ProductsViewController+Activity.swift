import Foundation

// MARK: - SearchableActivity Conformance
extension ProductsViewController: SearchableActivityConvertible {
    var activityType: String {
        return WooActivityType.products.rawValue
    }

    var activityTitle: String {
        return NSLocalizedString("Products", comment: "Title of the 'Products' tab - used for spotlight indexing on iOS.")
    }

    var activityDescription: String? {
        return NSLocalizedString("Create, edit, and publish products.",
                                 comment: "Description of the 'Products' screen - used for spotlight indexing on iOS.")
    }

    var activityKeywords: Set<String>? {
        let keyWordString = NSLocalizedString("woocommerce, woo, products, categories, new product, search products",
                                              comment: "This is a comma separated list of keywords used for spotlight indexing of the 'Products' tab.")
        return keyWordString.setOfTags()
    }
}
