import Foundation
import Yosemite

/// Syncable implementation for booking services/events (bookable product) filtering
struct BookableProductListSyncable: ListSyncable {
    typealias StorageType = StorageProduct
    typealias ModelType = Product
    typealias ListFilterType = BookingProductFilter

    let siteID: Int64

    var title: String { Localization.title }

    var emptyStateMessage: String { Localization.noMembersFound }

    var emptyItemTitlePlaceholder: String? { nil }

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

    // MARK: - Display Configuration

    func displayName(for item: Product) -> String {
        item.name
    }

    /// Returns the description for an item
    func description(for item: Product) -> String? { nil }

    func filterItem(for item: Product) -> BookingProductFilter {
        BookingProductFilter(productID: item.productID, name: item.name)
    }
}

private extension BookableProductListSyncable {
    enum Localization {
        static let title = NSLocalizedString(
            "bookingServiceEventSelectorView.title",
            value: "Service / Event",
            comment: "Title of the booking service/event selector view"
        )
        static let noMembersFound = NSLocalizedString(
            "bookingServiceEventSelectorView.noMembersFound",
            value: "No service or event found",
            comment: "Text on the empty view of the booking service/event selector view"
        )
    }
}
