import Foundation
import Observation
import protocol Yosemite.POSBookingListFetchStrategyFactoryProtocol
import protocol Yosemite.POSBookingListFetchStrategy
import struct Yosemite.POSBooking
import class Yosemite.AsyncPaginationTracker
import enum Yosemite.POSBookingServiceError
import protocol Yosemite.POSBookingServiceProtocol
import enum Yosemite.BookingAttendanceStatus

protocol POSBookingListControllerProtocol {
    var bookingsViewState: POSBookingListState { get }
    var selectedBooking: POSBooking? { get }
    func loadBookings() async
    func refreshBookings() async
    func loadNextBookings() async
    func selectBooking(_ booking: POSBooking?)
    func cancelBooking(bookingID: Int64) async throws
    func updateAttendanceStatus(bookingID: Int64, status: BookingAttendanceStatus) async throws
}

protocol POSSearchingBookingListControllerProtocol: POSBookingListControllerProtocol {
    func searchBookings(searchTerm: String) async
    func clearSearchBookings()
}

@Observable final class POSBookingListController: POSSearchingBookingListControllerProtocol {
    var bookingsViewState: POSBookingListState
    private var strategyPaginationTracker: [String: AsyncPaginationTracker] = [:]
    private var fetchStrategy: POSBookingListFetchStrategy
    private var cachedBookings: [POSBooking] = []
    private(set) var selectedBooking: POSBooking?
    private let bookingListFetchStrategyFactory: POSBookingListFetchStrategyFactoryProtocol
    private let bookingService: POSBookingServiceProtocol

    private var paginationTracker: AsyncPaginationTracker {
        if let existing = strategyPaginationTracker[fetchStrategy.id] {
            return existing
        }
        let tracker = AsyncPaginationTracker()
        strategyPaginationTracker[fetchStrategy.id] = tracker
        return tracker
    }

    init(bookingListFetchStrategyFactory: POSBookingListFetchStrategyFactoryProtocol,
         initialState: POSBookingListState = .loading([])) {
        self.bookingsViewState = initialState
        self.bookingListFetchStrategyFactory = bookingListFetchStrategyFactory
        self.bookingService = bookingListFetchStrategyFactory.bookingService
        self.fetchStrategy = bookingListFetchStrategyFactory.defaultStrategy()
    }

    @MainActor
    func loadBookings() async {
        setCachedData()
        setLoadingState()
        await loadFirstPage()
    }

    @MainActor
    func refreshBookings() async {
        await loadFirstPage()
    }

    @MainActor
    func loadNextBookings() async {
        guard paginationTracker.hasNextPage else {
            return
        }
        let currentBookings = bookingsViewState.bookings
        bookingsViewState = .loading(currentBookings)
        do {
            _ = try await paginationTracker.ensureNextPageIsSynced { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchBookings(pageNumber: pageNumber)
            }
        } catch {
            bookingsViewState = .inlineError(currentBookings,
                                             error: .errorOnLoadingBookingsNextPage(error: error),
                                             context: .pagination)
        }
    }

    @MainActor
    func selectBooking(_ booking: POSBooking?) {
        selectedBooking = booking
    }

    @MainActor
    func cancelBooking(bookingID: Int64) async throws {
        try await bookingService.cancelBooking(bookingID: bookingID)
        await refreshBookings()
    }

    @MainActor
    func updateAttendanceStatus(bookingID: Int64, status: BookingAttendanceStatus) async throws {
        try await bookingService.updateAttendanceStatus(bookingID: bookingID, status: status)
        if let existing = bookingsViewState.bookings.first(where: { $0.id == bookingID }) {
            updateBooking(existing.copy(attendanceStatus: status))
        }
    }

    @MainActor
    func searchBookings(searchTerm: String) async {
        fetchStrategy = bookingListFetchStrategyFactory.searchStrategy(searchTerm: searchTerm)
        bookingsViewState = .loading([])
        await loadFirstPage()
    }

    @MainActor
    func clearSearchBookings() {
        fetchStrategy = bookingListFetchStrategyFactory.defaultStrategy()
        if cachedBookings.isNotEmpty {
            bookingsViewState = .loaded(cachedBookings, hasMoreItems: true)
        } else {
            bookingsViewState = .loading([])
            Task {
                await loadFirstPage()
            }
        }
    }
}

// MARK: - Private

private extension POSBookingListController {
    @MainActor
    func loadFirstPage() async {
        do {
            try await paginationTracker.resync { [weak self] pageNumber in
                guard let self else { return true }
                return try await fetchBookings(pageNumber: pageNumber, appendToExistingBookings: false)
            }
        } catch {
            let bookings = bookingsViewState.bookings
            if bookings.isEmpty {
                bookingsViewState = .error(.errorOnLoadingBookings(error: error))
            } else {
                bookingsViewState = .inlineError(bookings,
                                                 error: .errorOnLoadingBookings(error: error),
                                                 context: .refresh)
            }
        }
    }

    func setLoadingState() {
        if !fetchStrategy.showsLoadingWithItems {
            bookingsViewState = .loading([])
            return
        }

        let bookings = bookingsViewState.bookings
        let isInitialState = bookingsViewState.isLoading && bookings.isEmpty
        if !isInitialState {
            bookingsViewState = .loading(bookings)
        }
    }

    @MainActor
    func fetchBookings(pageNumber: Int, appendToExistingBookings: Bool = true) async throws -> Bool {
        do {
            let pagedBookings = try await fetchStrategy.fetchBookings(pageNumber: pageNumber)

            let existingBookings = appendToExistingBookings ? bookingsViewState.bookings : []
            let uniqueNewBookings = pagedBookings.items.filter { newBooking in
                !existingBookings.contains(where: { $0.id == newBooking.id })
            }
            let allBookings = appendToExistingBookings ? existingBookings + uniqueNewBookings : uniqueNewBookings

            bookingsViewState = allBookings.isEmpty ? .empty : .loaded(allBookings, hasMoreItems: pagedBookings.hasMorePages)

            if let selectedBookingID = selectedBooking?.id,
               let updatedSelectedBooking = allBookings.first(where: { $0.id == selectedBookingID }) {
                selectedBooking = updatedSelectedBooking
            }

            if fetchStrategy.supportsCaching {
                cachedBookings = allBookings
            }

            return pagedBookings.hasMorePages
        } catch POSBookingServiceError.requestCancelled {
            return true
        }
    }

    @MainActor
    func setCachedData() {
        guard fetchStrategy.supportsCaching else {
            return
        }

        guard !bookingsViewState.bookings.isEmpty || !cachedBookings.isEmpty else {
            return
        }

        bookingsViewState = .loading(cachedBookings)
    }

    @MainActor
    func updateBooking(_ updatedBooking: POSBooking) {
        let updatedBookings = bookingsViewState.bookings.map { booking in
            booking.id == updatedBooking.id ? updatedBooking : booking
        }
        bookingsViewState = bookingsViewState.updatingBookings(with: updatedBookings)
        cachedBookings = cachedBookings.map { booking in
            booking.id == updatedBooking.id ? updatedBooking : booking
        }
        if selectedBooking?.id == updatedBooking.id {
            selectedBooking = updatedBooking
        }
    }
}
