import Foundation
import Yosemite
import Networking
import struct Networking.PagedItems

// MARK: - Item Fetch Strategy

struct PrototypeItemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactoryProtocol {
    private let products: [POSItem]

    init(products: [POSItem]) {
        self.products = products
    }

    func defaultStrategy(analytics: POSItemFetchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy {
        PrototypePurchasableItemFetchStrategy(products: products)
    }

    func searchStrategy(searchTerm: String,
                        analytics: POSItemFetchAnalyticsTracking) -> PointOfSalePurchasableItemFetchStrategy {
        PrototypePurchasableItemFetchStrategy(products: products.filter {
            switch $0 {
            case .simpleProduct(let p):
                return p.name.localizedCaseInsensitiveContains(searchTerm)
            default:
                return false
            }
        })
    }
}

struct PrototypePurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    let products: [POSItem]

    func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        await MainActor.run { }
        try await Task.sleep(for: .milliseconds(100))
        return PagedItems(items: [], hasMorePages: false, totalItems: 0)
    }

    func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<POSProductVariation> {
        PagedItems(items: [], hasMorePages: false, totalItems: 0)
    }

    func fetchMixedItems(pageNumber: Int) async throws -> PagedItems<POSItem>? {
        PagedItems(items: products, hasMorePages: false, totalItems: products.count)
    }
}

// MARK: - Coupon Fetch Strategy

struct PrototypeCouponFetchStrategyFactory: PointOfSaleCouponFetchStrategyFactoryProtocol {
    var defaultStrategy: PointOfSaleCouponFetchStrategy {
        PrototypeCouponFetchStrategy()
    }

    func searchStrategy(searchTerm: String, analytics: POSItemFetchAnalyticsTracking) -> PointOfSaleCouponFetchStrategy {
        PrototypeCouponFetchStrategy()
    }
}

struct PrototypeCouponFetchStrategy: PointOfSaleCouponFetchStrategy {
    func fetchCoupons(pageNumber: Int) async throws -> PagedItems<POSItem> {
        // Yield to MainActor to serialize access to AsyncPaginationTracker
        // which has non-isolated mutable IndexSet properties
        await MainActor.run { }
        try await Task.sleep(for: .milliseconds(100))
        return PagedItems(items: [], hasMorePages: false, totalItems: 0)
    }

    func fetchLocalCoupons() async throws -> [POSItem] {
        []
    }
}

// MARK: - Order List Fetch Strategy

struct PrototypeOrderListFetchStrategyFactory: POSOrderListFetchStrategyFactoryProtocol {
    func defaultStrategy() -> POSOrderListFetchStrategy {
        PrototypeOrderListFetchStrategy()
    }

    func searchStrategy(searchTerm: String) -> POSOrderListFetchStrategy {
        PrototypeOrderListFetchStrategy()
    }
}

struct PrototypeOrderListFetchStrategy: POSOrderListFetchStrategy {
    var id: String { "PrototypeOrderListFetchStrategy" }
    var supportsCaching: Bool { false }
    var showsCachedDataWhileLoading: Bool { false }

    func fetchOrders(pageNumber: Int) async throws -> PagedItems<POSOrder> {
        await MainActor.run { }
        try await Task.sleep(for: .milliseconds(100))
        return PagedItems(items: [], hasMorePages: false, totalItems: 0)
    }

    func loadOrder(orderID: Int64) async throws -> POSOrder {
        fatalError("Not implemented for prototype")
    }

    func trackFetched(millisecondsSinceRequestSent: Int) {}
    func trackNextPageLoaded(pageNumber: Int) {}
}

// MARK: - Booking List Fetch Strategy

struct PrototypeBookingListFetchStrategyFactory: POSBookingListFetchStrategyFactoryProtocol {
    var bookingService: POSBookingServiceProtocol { PrototypeBookingService() }

    func defaultStrategy(filters: BookingFilters?) -> POSBookingListFetchStrategy {
        PrototypeBookingListFetchStrategy()
    }

    func searchStrategy(searchTerm: String, filters: BookingFilters?) -> POSBookingListFetchStrategy {
        PrototypeBookingListFetchStrategy()
    }
}

struct PrototypeBookingListFetchStrategy: POSBookingListFetchStrategy {
    var showsCachedDataWhileLoading: Bool { false }

    func fetchBookings(pageNumber: Int) async throws -> PagedItems<POSBooking> {
        PagedItems(items: [], hasMorePages: false, totalItems: 0)
    }

    @MainActor
    func fetchLocalBookings() -> [POSBooking] {
        []
    }
}

final class PrototypeBookingService: POSBookingServiceProtocol {
    func fetchBookings(siteID: Int64,
                       pageNumber: Int,
                       pageSize: Int,
                       filters: BookingFilters?,
                       searchQuery: String?) async throws -> PagedItems<POSBooking> {
        PagedItems(items: [], hasMorePages: false, totalItems: 0)
    }

    func fetchBooking(bookingID: Int64) async throws -> POSBooking {
        fatalError("Not implemented for prototype")
    }

    func cancelBooking(bookingID: Int64) async throws -> BookingStatus {
        .cancelled
    }

    func updateAttendanceStatus(bookingID: Int64, status: BookingAttendanceStatus) async throws -> BookingAttendanceStatus {
        status
    }

    func updateBookingNote(bookingID: Int64, note: String) async throws -> String {
        note
    }
}

// MARK: - Search History

struct PrototypeSearchHistoryProvider: POSSearchHistoryProviding {
    func saveSuccessfulSearch(term: String, for itemType: POSItemType) {}
    func searchHistory(for itemType: POSItemType) -> [String] { [] }
}

// MARK: - Barcode Scan Service

struct PrototypeBarcodeScanService: PointOfSaleBarcodeScanServiceProtocol {
    func getItem(barcode: String) async throws(PointOfSaleBarcodeScanError) -> POSItem {
        throw .notFound(scannedCode: barcode)
    }
}
