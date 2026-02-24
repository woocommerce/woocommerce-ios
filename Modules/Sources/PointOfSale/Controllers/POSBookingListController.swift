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
    func syncBookings()
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

@MainActor
@Observable final class POSBookingListController: POSSearchingBookingListControllerProtocol {
    var bookingsViewState: POSBookingListState
    private(set) var selectedDate: Date
    private var strategyPaginationTracker: [String: AsyncPaginationTracker] = [:]
    private var fetchStrategy: POSBookingListFetchStrategy
    private var activeSearchTerm: String?
    private(set) var selectedBooking: POSBooking?
    private let bookingListFetchStrategyFactory: POSBookingListFetchStrategyFactoryProtocol
    private let bookingService: POSBookingServiceProtocol
    private let siteTimezone: TimeZone
    private var loadTask: Task<Void, Never>?
    private var prefetchTasks: [Date: Task<Void, Never>] = [:]

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
        syncBookings()
    }

    func syncBookings() {
        let date = selectedDate
        prefetchDate(date)
        prefetchAdjacentDates(for: date)
    }

    func loadBookings() async {
        loadTask?.cancel()
        let filters = dateFilters(for: selectedDate)
        if let searchTerm = activeSearchTerm {
            fetchStrategy = bookingListFetchStrategyFactory.searchStrategy(searchTerm: searchTerm, filters: filters)
        } else {
            fetchStrategy = bookingListFetchStrategyFactory.defaultStrategy(filters: filters)
        }

        // Show cached bookings from local storage immediately (if any), then fetch fresh data from remote.
        showCachedBookingsOrLoadingIndicator()
        loadTask = Task { await loadFirstPage() }
        await loadTask?.value
        prefetchAdjacentDates(for: selectedDate)
    }

    func refreshBookings() async {
        loadTask?.cancel()
        loadTask = Task { await loadFirstPage() }
        await loadTask?.value
    }

    func loadNextBookings() async {
        // Wait for the initial page sync to finish before beginning pagination
        if case let .loading(bookings, .firstPage) = bookingsViewState, bookings.isNotEmpty, let loadTask {
            await loadTask.value
        }

        guard paginationTracker.hasNextPage,
              case .loaded(_, let hasMoreItems) = bookingsViewState, hasMoreItems else { return }

        loadTask = Task {
            let currentBookings = bookingsViewState.bookings
            bookingsViewState = .loading(currentBookings, context: .nextPage)
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
        await loadTask?.value
    }

    func selectBooking(_ booking: POSBooking?) {
        selectedBooking = booking
    }

    func cancelBooking(bookingID: Int64) async throws {
        let updatedStatus = try await bookingService.cancelBooking(bookingID: bookingID)
        if let existing = bookingsViewState.bookings.first(where: { $0.id == bookingID }) {
            updateBooking(existing.copy(status: updatedStatus))
        }
    }

    func updateAttendanceStatus(bookingID: Int64, status: BookingAttendanceStatus) async throws {
        let updatedStatus = try await bookingService.updateAttendanceStatus(bookingID: bookingID, status: status)
        if let existing = bookingsViewState.bookings.first(where: { $0.id == bookingID }) {
            updateBooking(existing.copy(attendanceStatus: updatedStatus))
        }
    }

    func updateBookingNote(bookingID: Int64, note: String) async throws {
        let updatedNote = try await bookingService.updateBookingNote(bookingID: bookingID, note: note)
        if let existingNote = bookingsViewState.bookings.first(where: { $0.id == bookingID }) {
            let updatedNote = existingNote.copy(bookingNote: updatedNote.isEmpty ? nil : updatedNote)
            updateBooking(updatedNote)
        }
    }

    func updateBooking(bookingID: Int64) async throws {
        let updatedBooking = try await bookingService.fetchBooking(bookingID: bookingID)
        updateBooking(updatedBooking)
    }

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

    func selectDate(_ date: Date) async {
        loadTask?.cancel()
        selectedDate = date
        let filters = dateFilters(for: date)
        if let searchTerm = activeSearchTerm {
            fetchStrategy = bookingListFetchStrategyFactory.searchStrategy(searchTerm: searchTerm, filters: filters)
            bookingsViewState = .loading([])
        } else {
            // Show cached bookings for the new date immediately (if previously prefetched).
            fetchStrategy = bookingListFetchStrategyFactory.defaultStrategy(filters: filters)
            let localBookings = fetchStrategy.fetchLocalBookings()
            bookingsViewState = .loading(localBookings)
        }

        // Then fetch fresh data from remote.
        loadTask = Task { await loadFirstPage() }
        await loadTask?.value
        prefetchAdjacentDates(for: date)
    }

    func goToPreviousDay() async {
        var calendar = Calendar.current
        calendar.timeZone = siteTimezone
        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: selectedDate) else { return }
        await selectDate(previousDay)
    }

    func goToNextDay() async {
        var calendar = Calendar.current
        calendar.timeZone = siteTimezone
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) else { return }
        await selectDate(nextDay)
    }

    func searchBookings(searchTerm: String) async {
        loadTask?.cancel()
        activeSearchTerm = searchTerm
        fetchStrategy = bookingListFetchStrategyFactory.searchStrategy(searchTerm: searchTerm, filters: dateFilters(for: selectedDate))
        bookingsViewState = .loading([])
        loadTask = Task { await loadFirstPage() }
        await loadTask?.value
    }

    func clearSearchBookings() {
        loadTask?.cancel()
        activeSearchTerm = nil
        fetchStrategy = bookingListFetchStrategyFactory.defaultStrategy(filters: dateFilters(for: selectedDate))
        let localBookings = fetchStrategy.fetchLocalBookings()
        if localBookings.isNotEmpty {
            bookingsViewState = .loaded(localBookings, hasMoreItems: true)
        } else {
            bookingsViewState = .loading([])
            loadTask = Task { await loadFirstPage() }
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
    func prefetchAdjacentDates(for date: Date) {
        var calendar = Calendar.current
        calendar.timeZone = siteTimezone
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: date) {
            prefetchDate(yesterday)
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) {
            prefetchDate(tomorrow)
        }
    }

    func prefetchDate(_ date: Date) {
        var calendar = Calendar.current
        calendar.timeZone = siteTimezone
        let normalizedDate = calendar.startOfDay(for: date)

        guard prefetchTasks[normalizedDate] == nil else { return }

        let strategy = bookingListFetchStrategyFactory.defaultStrategy(filters: dateFilters(for: normalizedDate))
        prefetchTasks[normalizedDate] = Task { [weak self] in
            do {
                _ = try await strategy.fetchBookings(pageNumber: 1)
            } catch {
                DDLogError("⛔️ Failed to prefetch bookings for \(normalizedDate): \(error)")
            }
            self?.prefetchTasks[normalizedDate] = nil
        }
    }

    static func todayInSiteTimezone(_ timezone: TimeZone) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        return calendar.startOfDay(for: Date())
    }

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

    /// Sets the view state before a remote fetch begins.
    /// - If local storage has bookings for the current filters, show them immediately with a loading indicator.
    /// - If the strategy doesn't cache data (e.g. search), show an empty loading state.
    /// - Otherwise, keep displaying whatever bookings are already on screen while loading refreshes.
    func showCachedBookingsOrLoadingIndicator() {
        let localBookings = fetchStrategy.fetchLocalBookings()
        if localBookings.isNotEmpty {
            bookingsViewState = .loading(localBookings)
            return
        }

        guard fetchStrategy.showsCachedDataWhileLoading else {
            bookingsViewState = .loading([])
            return
        }

        // For the default strategy, preserve existing bookings on screen while loading.
        // Skip if we're already in the initial empty loading state (nothing to preserve).
        let existingBookings = bookingsViewState.bookings
        let isInitialEmptyLoading = bookingsViewState.isLoading && existingBookings.isEmpty
        if !isInitialEmptyLoading {
            bookingsViewState = .loading(existingBookings)
        }
    }

    func fetchBookings(pageNumber: Int, appendToExistingBookings: Bool = true) async throws -> Bool {
        let strategyID = fetchStrategy.id
        do {
            let pagedBookings = try await fetchStrategy.fetchBookings(pageNumber: pageNumber)

            // Discard results if context changed (e.g. date switched, search started)
            guard fetchStrategy.id == strategyID else { return true }

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

            return pagedBookings.hasMorePages
        } catch POSBookingServiceError.requestCancelled {
            return true
        }
    }

    func updateBooking(_ updatedBooking: POSBooking) {
        let updatedBookings = bookingsViewState.bookings.map { booking in
            booking.id == updatedBooking.id ? updatedBooking : booking
        }
        bookingsViewState = bookingsViewState.updatingBookings(with: updatedBookings)
        if selectedBooking?.id == updatedBooking.id {
            selectedBooking = updatedBooking
        }
    }
}
