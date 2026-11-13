import Foundation

/// Keeps products in the order of the pages that loaded them.
///
/// The store sorts each page with its database collation, which can differ from the local sort.
/// Sorting all loaded products locally can then move products from a new page above products from earlier pages.
///
struct ProductListPageOrder {
    private struct Entry {
        let pageNumber: Int
        let name: String
    }

    private var entries: [Int64: Entry] = [:]

    /// Forgets the recorded pages, e.g. when the sort or the filters change, or when the first page replaces the stored products.
    ///
    mutating func reset() {
        entries = [:]
    }

    /// Records the page of each stored product.
    ///
    /// - Parameters:
    ///   - products: IDs and names of the stored products in local sort order.
    ///   - syncingPageNumber: the page being synced. New products are recorded for this page.
    ///     Without a page sync, a new product moves to the page of the product before it.
    ///     A renamed product always moves to the page of the product before it.
    ///
    mutating func record(_ products: [(productID: Int64, name: String)], syncingPageNumber: Int?) {
        let productIDs = Set(products.map(\.productID))
        entries = entries.filter { productIDs.contains($0.key) }

        var previousPageNumber = SyncingCoordinator.Defaults.pageFirstIndex
        for product in products {
            let pageNumber: Int
            if let entry = entries[product.productID] {
                pageNumber = entry.name == product.name ? entry.pageNumber : previousPageNumber
            } else {
                pageNumber = syncingPageNumber ?? previousPageNumber
            }
            entries[product.productID] = Entry(pageNumber: pageNumber, name: product.name)
            previousPageNumber = pageNumber
        }
    }

    /// Returns the products grouped by recorded page, keeping their local order within a page.
    /// A product without a recorded page stays in the page of the product before it.
    ///
    func ordered(_ products: [ProductListItem]) -> [ProductListItem] {
        var previousPageNumber = SyncingCoordinator.Defaults.pageFirstIndex
        let productPageNumbers = products.map { product in
            let pageNumber = entries[product.productID]?.pageNumber ?? previousPageNumber
            previousPageNumber = pageNumber
            return pageNumber
        }

        return zip(products, productPageNumbers)
            .enumerated()
            .sorted { ($0.element.1, $0.offset) < ($1.element.1, $1.offset) }
            .map(\.element.0)
    }
}
