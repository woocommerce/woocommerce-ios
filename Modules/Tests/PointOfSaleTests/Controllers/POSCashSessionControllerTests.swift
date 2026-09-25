import Foundation
import Testing
@testable import PointOfSale

@MainActor
struct POSCashSessionControllerTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func test_loadCurrentSession_when_service_throws_unsupported_then_flags_unsupported_without_load_error() async {
        // Given
        let controller = POSCashSessionController(service: POSMockCashSessionService(isUnsupported: true))

        // When
        await controller.loadCurrentSession()

        // Then
        #expect(controller.isCashSessionsUnsupported)
        #expect(controller.currentLoadError == nil)
        #expect(controller.currentSession == nil)
    }

    @Test func test_loadCurrentSession_when_service_throws_other_error_then_sets_load_error_and_not_unsupported() async {
        // Given
        let controller = POSCashSessionController(service: POSMockCashSessionService(failCurrentLoad: true))

        // When
        await controller.loadCurrentSession()

        // Then
        #expect(!controller.isCashSessionsUnsupported)
        #expect(controller.currentLoadError == POSCashSessionServiceError.previewUnavailable.localizedDescription)
    }

    @Test func test_load_when_using_mock_service_then_shows_prototype_past_sessions_and_computed_totals() async throws {
        // Given
        let controller = POSCashSessionController(service: POSMockCashSessionService(now: { now }))

        // When
        await controller.load()

        // Then
        #expect(controller.currentSession == nil)
        #expect(controller.pastSessions.map(\.id) == [1681891, 1681884, 1681877, 1681869])
        let first = try #require(controller.pastSessions.first)
        #expect(first.cashSales == 375)
        #expect(first.cashRefunds == 89)
        #expect(first.paidInOut == Decimal(85) / 2)
        #expect(first.expectedCash == Decimal(1057) / 2)
        #expect(first.difference == -5)
    }

    @Test func test_start_record_and_close_then_moves_session_to_past_sessions() async throws {
        // Given
        let controller = POSCashSessionController(service: POSMockCashSessionService(now: { now }, currentActor: "Tester"))
        await controller.load()

        // When
        #expect(await controller.start(openingCash: 200))
        #expect(await controller.record(kind: .payIn, amount: 100, note: "Change order"))
        #expect(await controller.record(kind: .payOut, amount: 30, note: "Window cleaner"))
        let active = try #require(controller.currentSession)

        // Then
        #expect(active.expectedCash == 270)
        #expect(active.movements.count == 2)
        let closed = try #require(await controller.close(countedCash: 265, note: "Short by five"))
        #expect(closed.difference == -5)
        #expect(closed.closedBy == "Tester")
        #expect(controller.currentSession == nil)
        #expect(controller.pastSessions.first?.id == closed.id)
    }

    @Test func test_refreshPastSessions_when_service_returns_new_page_then_replaces_sessions_without_loading_state() async {
        // Given
        let service = MockPOSCashSessionService()
        service.pastSessionsToReturn = .init(sessions: [makeSession(id: 1)], hasMore: false)
        let controller = POSCashSessionController(service: service)
        await controller.loadPastSessions()
        service.pastSessionsToReturn = .init(sessions: [makeSession(id: 2), makeSession(id: 1)], hasMore: false)
        var isLoadingDuringRefresh: Bool?
        var isRefreshingDuringRefresh: Bool?
        var sessionIDsDuringRefresh: [Int64]?
        service.onPastSessionsRequested = { _ in
            isLoadingDuringRefresh = controller.isLoadingPastSessions
            isRefreshingDuringRefresh = controller.isRefreshingPastSessions
            sessionIDsDuringRefresh = controller.pastSessions.map(\.id)
        }

        // When
        await controller.refreshPastSessions()

        // Then
        #expect(isLoadingDuringRefresh == false)
        #expect(isRefreshingDuringRefresh == true)
        #expect(sessionIDsDuringRefresh == [1])
        #expect(controller.pastSessions.map(\.id) == [2, 1])
        #expect(controller.isRefreshingPastSessions == false)
        #expect(service.requestedPastSessionPages == [1, 1])
    }

    @Test func test_refreshPastSessions_when_service_fails_then_sets_pastLoadError() async {
        // Given
        let service = MockPOSCashSessionService()
        service.pastSessionsToReturn = .init(sessions: [makeSession(id: 1)], hasMore: false)
        let controller = POSCashSessionController(service: service)
        await controller.loadPastSessions()
        service.pastSessionsError = POSCashSessionServiceError.previewUnavailable

        // When
        await controller.refreshPastSessions()

        // Then
        #expect(controller.pastLoadError == POSCashSessionServiceError.previewUnavailable.localizedDescription)
        #expect(controller.isRefreshingPastSessions == false)
    }

    @Test func test_refreshPastSessions_when_next_page_failed_then_clears_page_error_and_resets_paging() async {
        // Given
        let service = MockPOSCashSessionService()
        service.pastSessionsToReturn = .init(sessions: [makeSession(id: 1)], hasMore: true)
        let controller = POSCashSessionController(service: service)
        await controller.loadPastSessions()
        service.pastSessionsError = POSCashSessionServiceError.previewUnavailable
        await controller.loadNextPastSessions()
        #expect(controller.pastPageError != nil)
        service.pastSessionsError = nil

        // When
        await controller.refreshPastSessions()
        await controller.loadNextPastSessions()

        // Then
        #expect(controller.pastPageError == nil)
        #expect(controller.pastLoadError == nil)
        #expect(service.requestedPastSessionPages == [1, 2, 1, 2])
    }

    @Test func test_close_when_revision_conflicts_then_refreshes_and_requires_a_new_count() async throws {
        // Given
        let service = MockPOSCashSessionService()
        service.currentSessionToReturn = POSCashSession(id: 12, openedAt: now, openedBy: "Tester", openingCash: 10,
                                                        movements: [], revision: 1)
        let controller = POSCashSessionController(service: service)
        await controller.loadCurrentSession()
        service.currentSessionToReturn = POSCashSession(id: 12, openedAt: now, openedBy: "Tester", openingCash: 20,
                                                        movements: [], revision: 2)
        service.closeError = POSCashSessionServiceError.sessionChanged

        // When
        let firstClose = await controller.close(countedCash: 10, note: nil)

        // Then
        #expect(firstClose == nil)
        #expect(controller.currentSession?.revision == 2)
        #expect(controller.currentSession?.expectedCash == 20)
        #expect(controller.requiresCloseRecount)
        #expect(service.closeExpectedRevisions == [1])
        #expect(await controller.close(countedCash: 20, note: nil) == nil)
        #expect(service.closeCallCount == 1)

        // When: the cashier reviews the new total and enters a new count.
        #expect(controller.acknowledgeFreshCloseCount())
        service.closeError = nil
        service.closeSessionToReturn = POSCashSession(id: 12, openedAt: now, openedBy: "Tester", openingCash: 20,
                                                      movements: [], closedAt: now, countedCash: 20, revision: 3)
        _ = try #require(await controller.close(countedCash: 20, note: nil))
        #expect(service.closeExpectedRevisions == [1, 2])
    }

    @Test func test_close_when_conflict_refresh_fails_then_blocks_stale_retries() async {
        // Given
        let service = MockPOSCashSessionService()
        service.currentSessionToReturn = POSCashSession(id: 12, openedAt: now, openedBy: "Tester", openingCash: 10,
                                                        movements: [], revision: 1)
        let controller = POSCashSessionController(service: service)
        await controller.loadCurrentSession()
        service.closeError = POSCashSessionServiceError.sessionChanged
        service.currentSessionError = POSCashSessionServiceError.previewUnavailable

        // When
        _ = await controller.close(countedCash: 10, note: nil)

        // Then
        #expect(controller.requiresCloseRecount)
        #expect(controller.closeRefreshError != nil)
        #expect(!controller.acknowledgeFreshCloseCount())
        _ = await controller.close(countedCash: 10, note: nil)
        #expect(service.closeCallCount == 1)
        #expect(controller.currentSession?.revision == 1)
    }

    private func makeSession(id: Int64) -> POSCashSession {
        .init(id: id, openedAt: now, openedBy: "Tester", openingCash: 0, movements: [], closedAt: now, closedBy: "Tester")
    }
}
