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
    var isPaginating: Bool { get }
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
}

protocol POSSearchingBookingListControllerProtocol: POSBookingListControllerProtocol {
    func searchBookings(searchTerm: String) async
    func clearSearchBookings()
}

@Observable final class POSBookingListController: POSSearchingBookingListControllerProtocol {
    var bookingsViewState: POSBookingListState
    private(set) var selectedDate: Date
    private(set) var isPaginating: Bool = false
    private var strategyPaginationTracker: [String: AsyncPaginationTracker] = [:]
    private var fetchStrategy: POSBookingListFetchStrategy
    private var activeSearchTerm: String?
    private(set) var selectedBooking: POSBooking?
    private let bookingListFetchStrategyFactory: POSBookingListFetchStrategyFactoryProtocol
    private let bookingService: POSBookingServiceProtocol
    private let siteTimezone: TimeZone
    private var loadTask: Task<Void, Never>?
    private var prefetchTask: Task<Void, Never>?

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

    func syncBookings() {
        prefetchTask?.cancel()
        let date = selectedDate
        prefetchTask = Task {
            let todayStrategy = bookingListFetchStrategyFactory.defaultStrategy(filters: dateFilters(for: date))
            do {
                _ = try await todayStrategy.fetchBookings(pageNumber: 1)
            } catch {
                DDLogError("⛔️ Failed to prefetch bookings for today: \(error)")
            }
            await syncAdjacentDateBookings(for: date)
        }
    }

    @MainActor
    func loadBookings() async {
        loadTask?.cancel()
        prefetchTask?.cancel()
        isPaginating = false
        let filters = dateFilters(for: selectedDate)
        if let searchTerm = activeSearchTerm {
            fetchStrategy = bookingListFetchStrategyFactory.searchStrategy(searchTerm: searchTerm, filters: filters)
        } else {
            fetchStrategy = bookingListFetchStrategyFactory.defaultStrategy(filters: filters)
        }
        setLocalDataOrLoadingState()
        loadTask = Task { await loadFirstPage() }
        await loadTask?.value
        prefetchTask = Task { await syncAdjacentDateBookings(for: selectedDate) }
    }

    @MainActor
    func refreshBookings() async {
        loadTask?.cancel()
        isPaginating = false
        loadTask = Task { await loadFirstPage() }
        await loadTask?.value
    }

    @MainActor
    func loadNextBookings() async {
        guard paginationTracker.hasNextPage else {
            return
        }
        isPaginating = true
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
        isPaginating = false
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
        loadTask?.cancel()
        prefetchTask?.cancel()
        isPaginating = false
        selectedDate = date
        let filters = dateFilters(for: date)
        if let searchTerm = activeSearchTerm {
            fetchStrategy = bookingListFetchStrategyFactory.searchStrategy(searchTerm: searchTerm, filters: filters)
            bookingsViewState = .loading([])
        } else {
            fetchStrategy = bookingListFetchStrategyFactory.defaultStrategy(filters: filters)
            let localBookings = fetchStrategy.fetchLocalBookings()
            bookingsViewState = .loading(localBookings)
        }
        loadTask = Task { await loadFirstPage() }
        await loadTask?.value
        prefetchTask = Task { await syncAdjacentDateBookings(for: date) }
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
        loadTask?.cancel()
        isPaginating = false
        activeSearchTerm = searchTerm
        fetchStrategy = bookingListFetchStrategyFactory.searchStrategy(searchTerm: searchTerm, filters: dateFilters(for: selectedDate))
        bookingsViewState = .loading([])
        loadTask = Task { await loadFirstPage() }
        await loadTask?.value
    }

    @MainActor
    func clearSearchBookings() {
        loadTask?.cancel()
        isPaginating = false
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
    func syncAdjacentDateBookings(for date: Date) async {
        var calendar = Calendar.current
        calendar.timeZone = siteTimezone
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: date),
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) else {
            return
        }
        let yesterdayStrategy = bookingListFetchStrategyFactory.defaultStrategy(filters: dateFilters(for: yesterday))
        let tomorrowStrategy = bookingListFetchStrategyFactory.defaultStrategy(filters: dateFilters(for: tomorrow))

        async let yesterdayFetch: Void = {
            do {
                _ = try await yesterdayStrategy.fetchBookings(pageNumber: 1)
            } catch {
                DDLogError("⛔️ Failed to prefetch bookings for yesterday: \(error)")
            }
        }()
        async let tomorrowFetch: Void = {
            do {
                _ = try await tomorrowStrategy.fetchBookings(pageNumber: 1)
            } catch {
                DDLogError("⛔️ Failed to prefetch bookings for tomorrow: \(error)")
            }
        }()
        _ = await (yesterdayFetch, tomorrowFetch)
    }

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

    @MainActor
    func setLocalDataOrLoadingState() {
        let localBookings = fetchStrategy.fetchLocalBookings()
        if localBookings.isNotEmpty {
            bookingsViewState = .loading(localBookings)
        } else if !fetchStrategy.showsLoadingWithItems {
            bookingsViewState = .loading([])
        } else {
            let bookings = bookingsViewState.bookings
            let isInitialState = bookingsViewState.isLoading && bookings.isEmpty
            if !isInitialState {
                bookingsViewState = .loading(bookings)
            }
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

            return pagedBookings.hasMorePages
        } catch POSBookingServiceError.requestCancelled {
            return true
        }
    }

    @MainActor
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
