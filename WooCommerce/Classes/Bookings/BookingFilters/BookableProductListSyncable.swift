import Foundation
import Yosemite

/// Syncable implementation for booking services/events (bookable product) filtering
struct BookableProductListSyncable: ListSyncable {
    typealias StorageType = StorageProduct
    typealias ModelType = Product
    typealias ListFilterType = BookingProductFilter

    let siteID: Int64

    let title = Localization.title

    let emptyStateMessage = Localization.noServiceFound
    let emptyItemTitlePlaceholder: String? = nil

    let searchConfiguration: ListSearchConfiguration? = ListSearchConfiguration(
        searchPrompt: Localization.searchPrompt,
        emptySearchTitle: Localization.noServiceFound,
        emptySearchDescription: Localization.emptySearchDescription
    )

    let selectionDisabledMessage: String? = nil

    // MARK: - ResultsController Configuration

    func createPredicate() -> NSPredicate {
        NSPredicate(format: "siteID == %lld AND productTypeKey == %@", siteID, ProductType.booking.rawValue)
    }

    func createSortDescriptors() -> [NSSortDescriptor] {
        [NSSortDescriptor(key: "productID", ascending: false)]
    }

    // MARK: - Sync Configuration

    func createSyncAction(
        pageNumber: Int,
        pageSize: Int,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) -> Action {
        ProductAction.synchronizeProducts(
            siteID: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            stockStatus: nil,
            productStatus: nil,
            productType: .booking,
            productCategory: nil,
            sortOrder: .dateDescending,
            productIDs: [],
            excludedProductIDs: [],
            shouldDeleteStoredProductsOnFirstPage: true,
            onCompletion: completion
        )
    }

    /// Creates the action to search items with keyword
    func createSearchAction(keyword: String, pageNumber: Int, pageSize: Int, completion: @escaping (Result<Bool, Error>) -> Void) -> Action {
        ProductAction.searchProducts(
            siteID: siteID,
            keyword: keyword,
            filter: .name,
            pageNumber: pageNumber,
            pageSize: pageSize,
            productType: .booking,
            onCompletion: completion
        )
    }

    /// Creates the predicate for filtering search results
    func createSearchPredicate(keyword: String) -> NSPredicate? {
        NSPredicate(format: "SUBQUERY(searchResults, $result, $result.keyword = %@).@count > 0", keyword)
    }

    // MARK: - Display Configuration

    func displayName(for item: Product) -> String {
        item.name
    }

    /// Returns the description for an item
    func description(for item: Product) -> String? { nil }

    func selectionEnabled(for item: Product) -> Bool { true }

    func filterItem(for item: Product) -> BookingProductFilter {
        BookingProductFilter(productID: item.productID, name: item.name)
    }
}

private extension BookableProductListSyncable {
    enum Localization {
        static let title = NSLocalizedString(
            "bookingServiceSelectorView.title",
            value: "Service",
            comment: "Title of the booking service selector view"
        )
        static let noServiceFound = NSLocalizedString(
            "bookingServiceSelectorView.noMembersFound",
            value: "No service found",
            comment: "Text on the empty view of the booking service selector view"
        )
        static let searchPrompt = NSLocalizedString(
            "bookingServiceSelectorView.searchPrompt",
            value: "Search service",
            comment: "Prompt in the search bar of the booking service selector view"
        )
        static let emptySearchDescription = NSLocalizedString(
            "bookingServiceEventSelectorView.emptySearchDescription",
            value: "Try adjusting your search term to see more results",
            comment: "Message on the empty search result view of the booking service/event selector view"
        )
    }
}
