import CocoaLumberjackSwift
import Foundation
import Observation
import protocol Yosemite.POSBookingListFetchStrategyFactoryProtocol
import protocol Yosemite.POSBookingListFetchStrategy
import struct Yosemite.POSBooking
import class Yosemite.AsyncPaginationTracker
import enum Yosemite.POSBookingServiceError
import protocol Yosemite.POSBookingServiceProtocol
import enum Yosemite.BookingAttendanceStatus
import struct Yosemite.BookingFilters
import enum Yosemite.BookingStatus

protocol POSBookingListControllerProtocol {
    var bookingsViewState: POSBookingListState { get }
    var selectedBooking: POSBooking? { get }
    var selectedDate: Date { get }
    func loadBookings() async
    func refreshBookings() async
    func loadNextBookings() async
    func selectBooking(_ booking: POSBooking?)
    func selectDate(_ date: Date) async
    func goToPreviousDay() async
    func goToNextDay() async
    func cancelBooking(bookingID: Int64) async throws
    func updateAttendanceStatus(bookingID: Int64, status: BookingAttendanceStatus) async throws
    func updateBooking(bookingID: Int64) async throws
    func updateBookingOptimistically(bookingID: Int64, optimisticUpdate: (POSBooking) -> POSBooking) async
    func updateBookingNote(bookingID: Int64, note: String) async throws
}

protocol POSSearchingBookingListControllerProtocol: POSBookingListControllerProtocol {
    func searchBookings(searchTerm: String) async
    func clearSearchBookings()
}

@Observable final class POSBookingListController: POSSearchingBookingListControllerProtocol {
    var bookingsViewState: POSBookingListState
    private(set) var selectedDate: Date
    private var strategyPaginationTracker: [String: AsyncPaginationTracker] = [:]
    private var fetchStrategy: POSBookingListFetchStrategy
    private var cachedBookings: [POSBooking] = []
    private var activeSearchTerm: String?
    private(set) var selectedBooking: POSBooking?
    private let bookingListFetchStrategyFactory: POSBookingListFetchStrategyFactoryProtocol
    private let bookingService: POSBookingServiceProtocol
    private let siteTimezone: TimeZone

    private var paginationTracker: AsyncPaginationTracker {
        if let existing = strategyPaginationTracker[fetchStrategy.id] {
            return existing
        }
        let tracker = AsyncPaginationTracker()
        strategyPaginationTracker[fetchStrategy.id] = tracker
        return tracker
    }

    init(bookingListFetchStrategyFactory: POSBookingListFetchStrategyFactoryProtocol,
         siteTimezone: TimeZone,
         initialDate: Date? = nil,
         initialState: POSBookingListState = .loading([])) {
        self.siteTimezone = siteTimezone
        self.selectedDate = initialDate ?? Self.todayInSiteTimezone(siteTimezone)
        self.bookingsViewState = initialState
        self.bookingListFetchStrategyFactory = bookingListFetchStrategyFactory
        self.bookingService = bookingListFetchStrategyFactory.bookingService
        self.fetchStrategy = bookingListFetchStrategyFactory.defaultStrategy(filters: nil)
    }

    @MainActor
    func loadBookings() async {
        let filters = dateFilters(for: selectedDate)
        if let searchTerm = activeSearchTerm {
            fetchStrategy = bookingListFetchStrategyFactory.searchStrategy(searchTerm: searchTerm, filters: filters)
        } else {
            fetchStrategy = bookingListFetchStrategyFactory.defaultStrategy(filters: filters)
        }
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
        let updatedStatus = try await bookingService.cancelBooking(bookingID: bookingID)
        if let existing = bookingsViewState.bookings.first(where: { $0.id == bookingID }) {
            updateBooking(existing.copy(status: updatedStatus))
        }
    }

    @MainActor
    func updateAttendanceStatus(bookingID: Int64, status: BookingAttendanceStatus) async throws {
        let updatedStatus = try await bookingService.updateAttendanceStatus(bookingID: bookingID, status: status)
        if let existing = bookingsViewState.bookings.first(where: { $0.id == bookingID }) {
            updateBooking(existing.copy(attendanceStatus: updatedStatus))
        }
    }

    @MainActor
    func updateBookingNote(bookingID: Int64, note: String) async throws {
        let updatedNote = try await bookingService.updateBookingNote(bookingID: bookingID, note: note)
        if let existing = bookingsViewState.bookings.first(where: { $0.id == bookingID }) {
            updateBooking(existing.copy(bookingNote: updatedNote.isEmpty ? nil : updatedNote))
        }
    }

    @MainActor
    func updateBooking(bookingID: Int64) async throws {
        let updatedBooking = try await bookingService.fetchBooking(bookingID: bookingID)
        updateBooking(updatedBooking)
    }

    @MainActor
    func updateBookingOptimistically(bookingID: Int64, optimisticUpdate: (POSBooking) -> POSBooking) async {
        guard let existing = bookingsViewState.bookings.first(where: { $0.id == bookingID }) else {
            return
        }

        let optimisticBooking = optimisticUpdate(existing)
        updateBooking(optimisticBooking)

        do {
            let realBooking = try await bookingService.fetchBooking(bookingID: bookingID)
            updateBooking(realBooking)
        } catch {
            DDLogError("⛔️ Failed to fetch booking \(bookingID) after optimistic update: \(error)")
        }
    }

    @MainActor
    func selectDate(_ date: Date) async {
        selectedDate = date
        cachedBookings = []
        let filters = dateFilters(for: date)
        if let searchTerm = activeSearchTerm {
            fetchStrategy = bookingListFetchStrategyFactory.searchStrategy(searchTerm: searchTerm, filters: filters)
        } else {
            fetchStrategy = bookingListFetchStrategyFactory.defaultStrategy(filters: filters)
        }
        bookingsViewState = .loading([])
        await loadFirstPage()
    }

    @MainActor
    func goToPreviousDay() async {
        var calendar = Calendar.current
        calendar.timeZone = siteTimezone
        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: selectedDate) else { return }
        await selectDate(previousDay)
    }

    @MainActor
    func goToNextDay() async {
        var calendar = Calendar.current
        calendar.timeZone = siteTimezone
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) else { return }
        await selectDate(nextDay)
    }

    @MainActor
    func searchBookings(searchTerm: String) async {
        activeSearchTerm = searchTerm
        fetchStrategy = bookingListFetchStrategyFactory.searchStrategy(searchTerm: searchTerm, filters: dateFilters(for: selectedDate))
        bookingsViewState = .loading([])
        await loadFirstPage()
    }

    @MainActor
    func clearSearchBookings() {
        activeSearchTerm = nil
        fetchStrategy = bookingListFetchStrategyFactory.defaultStrategy(filters: dateFilters(for: selectedDate))
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

// MARK: - Date Helpers

extension POSBookingListController {
    func dateFilters(for date: Date) -> BookingFilters {
        var calendar = Calendar.current
        calendar.timeZone = siteTimezone
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) else {
            return BookingFilters()
        }

        let formatter = ISO8601DateFormatter()
        formatter.timeZone = siteTimezone

        return BookingFilters(
            startDateBefore: formatter.string(from: endOfDay),
            startDateAfter: formatter.string(from: startOfDay)
        )
    }
}

// MARK: - Private

private extension POSBookingListController {
    static func todayInSiteTimezone(_ timezone: TimeZone) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        return calendar.startOfDay(for: Date())
    }

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
