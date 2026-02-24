import Foundation
import enum Alamofire.AFError
import class Networking.BookingsRemote
import struct NetworkingCore.PagedItems
import protocol Storage.StorageManagerType
import class WooFoundationCore.CurrencyFormatter

public protocol POSBookingListFetchStrategy {
    func fetchBookings(pageNumber: Int) async throws -> PagedItems<POSBooking>
    @MainActor func fetchLocalBookings() -> [POSBooking]
    var showsCachedDataWhileLoading: Bool { get }
    var id: String { get }
}

extension POSBookingListFetchStrategy {
    public var id: String {
        String(describing: type(of: self))
    }
}

struct POSDefaultBookingListFetchStrategy: POSBookingListFetchStrategy {
    private let bookingStoreMethods: BookingStoreMethodsProtocol
    private let storageManager: StorageManagerType
    private let storageBookingMapper: StorageBookingToPOSBookingMapper
    private let siteID: Int64
    private let pageSize: Int
    private let filters: BookingFilters?
    let showsCachedDataWhileLoading: Bool = true

    var id: String {
        "POSDefaultBookingListFetchStrategy-\(filters?.startDateAfter ?? "none")"
    }

    init(bookingStoreMethods: BookingStoreMethodsProtocol,
         storageManager: StorageManagerType,
         currencyFormatter: CurrencyFormatter,
         siteSettings: [SiteSetting] = [],
         siteID: Int64,
         filters: BookingFilters? = nil,
         pageSize: Int = 25) {
        self.bookingStoreMethods = bookingStoreMethods
        self.storageManager = storageManager
        self.storageBookingMapper = StorageBookingToPOSBookingMapper(currencyFormatter: currencyFormatter, siteSettings: siteSettings)
        self.siteID = siteID
        self.filters = filters
        self.pageSize = pageSize
    }

    func fetchBookings(pageNumber: Int) async throws -> PagedItems<POSBooking> {
        do {
            // Sync remote bookings into CoreData, then read them back as mapped POSBooking models.
            let cacheClearStrategy = cacheClearStrategy(for: pageNumber)
            let hasMorePages = try await bookingStoreMethods.synchronizeBookings(
                siteID: siteID,
                pageNumber: pageNumber,
                pageSize: pageSize,
                filters: filters,
                searchQuery: nil,
                order: .ascending,
                cacheClearStrategy: cacheClearStrategy
            )
            guard let filters else { return PagedItems(items: [], hasMorePages: hasMorePages, totalItems: nil) }
            let bookings = await fetchLocalBookingsSync(filters: filters, limit: nil)
            return PagedItems(items: bookings, hasMorePages: hasMorePages, totalItems: nil)
        } catch AFError.explicitlyCancelled, is CancellationError {
            throw POSBookingServiceError.requestCancelled
        }
    }

    @MainActor
    func fetchLocalBookings() -> [POSBooking] {
        guard let filters else { return [] }
        return fetchLocalBookingsSync(filters: filters, limit: pageSize)
    }
}

private extension POSDefaultBookingListFetchStrategy {
    /// On the first page, clear cached bookings matching the current filters (or all if no filters).
    /// On subsequent pages, keep the cache intact to allow appending.
    func cacheClearStrategy(for pageNumber: Int) -> BookingStoreMethods.CacheClearStrategy {
        guard pageNumber == 1 else {
            return .none
        }
        if let filters {
            return .filtersOnly(filters)
        }
        return .all
    }

    @MainActor
    func fetchLocalBookingsSync(filters: BookingFilters, limit: Int?) -> [POSBooking] {
        let bookingPredicate = NSPredicate.createBookingPredicate(siteID: siteID, filters: filters)
        let hasOrderPredicate = NSPredicate(format: "orderInfo != nil")
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [bookingPredicate, hasOrderPredicate])
        let sortByDate = NSSortDescriptor(keyPath: \StorageBooking.startDate, ascending: true)
        let sortByID = NSSortDescriptor(keyPath: \StorageBooking.bookingID, ascending: true)
        let resultsController = ResultsController<StorageBooking>(
            storageManager: storageManager,
            matching: predicate,
            fetchLimit: limit,
            sortedBy: [sortByDate, sortByID]
        )

        do {
            try resultsController.performFetch()
        } catch {
            return []
        }

        let readOnlyBookings = resultsController.fetchedObjects

        let resourceIDs = Set(readOnlyBookings.compactMap { $0.resourceID != 0 ? $0.resourceID : nil })
        let storedResources = loadStoredResources(resourceIDs: resourceIDs)

        return readOnlyBookings.compactMap { booking in
            let resource = storedResources[booking.resourceID]
            return storageBookingMapper.map(booking: booking, resource: resource)
        }
    }

    func loadStoredResources(resourceIDs: Set<Int64>) -> [Int64: BookingResource] {
        guard !resourceIDs.isEmpty else { return [:] }
        let predicate = NSPredicate(format: "siteID == %lld AND resourceID IN %@", siteID, Array(resourceIDs))
        let descriptor = NSSortDescriptor(keyPath: \StorageBookingResource.resourceID, ascending: true)
        let resultsController = ResultsController<StorageBookingResource>(
            storageManager: storageManager,
            matching: predicate,
            sortedBy: [descriptor]
        )
        do {
            try resultsController.performFetch()
        } catch {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: resultsController.fetchedObjects.map { ($0.resourceID, $0) })
    }
}

struct POSSearchBookingListFetchStrategy: POSBookingListFetchStrategy {
    private let bookingService: POSBookingServiceProtocol
    private let siteID: Int64
    private let searchTerm: String
    private let pageSize: Int
    private let filters: BookingFilters?
    let showsCachedDataWhileLoading: Bool = false

    var id: String {
        "POSSearchBookingListFetchStrategy-\(searchTerm)-\(filters?.startDateAfter ?? "none")"
    }

    init(bookingService: POSBookingServiceProtocol, siteID: Int64, searchTerm: String, filters: BookingFilters? = nil, pageSize: Int = 25) {
        self.bookingService = bookingService
        self.siteID = siteID
        self.searchTerm = searchTerm
        self.filters = filters
        self.pageSize = pageSize
    }

    func fetchBookings(pageNumber: Int) async throws -> PagedItems<POSBooking> {
        try await bookingService.fetchBookings(
            siteID: siteID,
            pageNumber: pageNumber,
            pageSize: pageSize,
            filters: filters,
            searchQuery: searchTerm
        )
    }

    @MainActor
    func fetchLocalBookings() -> [POSBooking] {
        []
    }
}
