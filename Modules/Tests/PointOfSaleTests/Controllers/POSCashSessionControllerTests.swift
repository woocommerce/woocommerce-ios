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

    @Test func test_record_when_adjustment_saved_but_refresh_fails_then_requires_reload() async {
        // Given
        let service = MockPOSCashSessionService()
        service.currentSessionToReturn = POSCashSession(id: 12, openedAt: now, openedBy: "Tester", openingCash: 10,
                                                        movements: [], revision: 1)
        let controller = POSCashSessionController(service: service)
        await controller.loadCurrentSession()
        service.movementError = POSCashSessionServiceError.movementRecordedRefreshFailed
        let requestID = UUID()

        // When
        let shouldDismissEntry = await controller.record(kind: .payIn, amount: 5, note: nil, requestID: requestID)

        // Then
        #expect(shouldDismissEntry)
        #expect(controller.currentLoadError == POSCashSessionServiceError.movementRecordedRefreshFailed.errorDescription)
        #expect(controller.errorMessage == nil)
        #expect(service.recordedMovementRequestIDs == [requestID])
    }

    @Test func test_record_when_server_rejects_pay_out_then_refreshes_expected_cash_and_keeps_error() async {
        // Given
        let service = MockPOSCashSessionService()
        service.currentSessionToReturn = POSCashSession(id: 12, openedAt: now, openedBy: "Tester", openingCash: 100,
                                                        movements: [], revision: 1)
        let controller = POSCashSessionController(service: service)
        await controller.loadCurrentSession()
        service.currentSessionToReturn = POSCashSession(id: 12, openedAt: now, openedBy: "Tester", openingCash: 40,
                                                        movements: [], revision: 2)
        service.movementError = POSCashSessionServiceError.insufficientCash

        // When
        let recorded = await controller.record(kind: .payOut, amount: 50, note: nil)

        // Then
        #expect(!recorded)
        #expect(controller.currentSession?.expectedCash == 40)
        #expect(controller.errorMessage == POSCashSessionServiceError.insufficientCash.errorDescription)
        #expect(service.recordedMovementRequestIDs.count == 1)
    }

    @Test func test_current_session_when_only_an_old_session_has_pending_cash_then_close_is_not_blocked() async {
        // Given
        let service = MockPOSCashSessionService()
        service.currentSessionToReturn = POSCashSession(id: 12, openedAt: now, openedBy: "Tester", openingCash: 100,
                                                        movements: [], revision: 1)
        service.pendingMovementSessionIDs = [11]
        let controller = POSCashSessionController(service: service)

        // When
        await controller.loadCurrentSession()

        // Then
        #expect(!controller.hasPendingCashMovements)
    }

    @Test(arguments: [false, true])
    func test_record_when_movement_is_saved_then_opens_drawer_in_recorded_session(isPayOut: Bool) async throws {
        // Given
        let session = POSCashSession(id: 12, openedAt: now, openedBy: "Tester", openingCash: 10,
                                     movements: [], revision: 1, drawerID: "Front till")
        let service = MockPOSCashSessionService()
        service.currentSessionToReturn = session
        service.movementSessionToReturn = session
        let drawerService = MockCashDrawerService()
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let drawer = POSCashDrawerController(service: drawerService, sessionService: service, userDefaults: defaults)
        let controller = POSCashSessionController(service: service, cashDrawer: drawer)
        await controller.loadCurrentSession()

        // When
        let event = await withCheckedContinuation { continuation in
            service.onDrawerEventRecorded = { continuation.resume(returning: $0) }
            Task { _ = await controller.record(kind: isPayOut ? .payOut : .payIn, amount: 5, note: nil) }
        }

        // Then
        #expect(event.reason == .noSale)
        #expect(service.recordedDrawerEventSessionIDs == [12])
        #expect(drawerService.openCallCount == 1)
        #expect(service.recordedMovementRequestIDs.count == 1)
    }

    @Test func test_record_when_write_is_confirmed_but_refresh_fails_then_opens_drawer() async throws {
        // Given
        let session = POSCashSession(id: 12, openedAt: now, openedBy: "Tester", openingCash: 10,
                                     movements: [], revision: 1, drawerID: "Front till")
        let service = MockPOSCashSessionService()
        service.currentSessionToReturn = session
        service.movementError = POSCashSessionServiceError.movementRecordedRefreshFailed
        let drawerService = MockCashDrawerService()
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let drawer = POSCashDrawerController(service: drawerService, sessionService: service, userDefaults: defaults)
        let controller = POSCashSessionController(service: service, cashDrawer: drawer)
        await controller.loadCurrentSession()

        // When
        let event = await withCheckedContinuation { continuation in
            drawer.onDrawerEvent = { continuation.resume(returning: $0) }
            Task { _ = await controller.record(kind: .payIn, amount: 5, note: nil) }
        }

        // Then
        #expect(event.reason == .noSale)
        #expect(drawerService.openCallCount == 1)
        #expect(controller.currentLoadError == POSCashSessionServiceError.movementRecordedRefreshFailed.errorDescription)
    }

    @Test(arguments: [
        (POSCashSessionMovement.Kind.payIn, "Could not record the pay in. Try again."),
        (.payOut, "Could not record the pay out. Try again.")
    ])
    func test_record_when_request_fails_then_shows_specific_movement_error(kind: POSCashSessionMovement.Kind,
                                                                            expectedMessage: String) async {
        // Given
        let service = MockPOSCashSessionService()
        service.currentSessionToReturn = POSCashSession(id: 12, openedAt: now, openedBy: "Tester", openingCash: 10,
                                                        movements: [], revision: 1)
        let drawerService = MockCashDrawerService()
        let drawer = POSCashDrawerController(service: drawerService)
        let controller = POSCashSessionController(service: service, cashDrawer: drawer)
        await controller.loadCurrentSession()
        service.movementError = NSError(domain: "test", code: 1)

        // When
        let recorded = await controller.record(kind: kind, amount: 5, note: nil)

        // Then
        #expect(!recorded)
        #expect(controller.errorMessage == expectedMessage)
        #expect(drawerService.openCallCount == 0)
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

    @Test func test_loadSessionDetail_when_reappearing_then_refreshes_cached_detail_without_clearing_it() async {
        // Given
        let service = MockPOSCashSessionService()
        service.sessionToReturn = makeSession(id: 12)
        let controller = POSCashSessionController(service: service)
        await controller.loadSessionDetail(id: 12)
        service.sessionToReturn = POSCashSession(id: 12, openedAt: now, openedBy: "Tester", openingCash: 20,
                                                 movements: [], closedAt: now, closedBy: "Tester", revision: 2)
        var visibleCashDuringRefresh: Decimal?
        var wasLoadingDuringRefresh = false
        service.onSessionRequested = { _ in
            visibleCashDuringRefresh = controller.sessionDetail?.openingCash
            wasLoadingDuringRefresh = controller.isLoadingSessionDetail
        }

        // When
        await controller.loadSessionDetail(id: 12)

        // Then
        #expect(visibleCashDuringRefresh == 0)
        #expect(wasLoadingDuringRefresh)
        #expect(controller.sessionDetail?.openingCash == 20)
        #expect(controller.sessionDetail?.revision == 2)
        #expect(service.requestedSessionIDs == [12, 12])
    }

    @Test func test_loadSessionDetail_when_refresh_fails_then_retains_detail_and_clears_error_after_retry() async {
        // Given
        let service = MockPOSCashSessionService()
        service.sessionToReturn = makeSession(id: 12)
        let controller = POSCashSessionController(service: service)
        await controller.loadSessionDetail(id: 12)
        service.sessionError = POSCashSessionServiceError.previewUnavailable

        // When
        await controller.loadSessionDetail(id: 12)

        // Then
        #expect(controller.sessionDetail?.id == 12)
        #expect(controller.sessionDetailError != nil)
        service.sessionError = nil
        await controller.loadSessionDetail(id: 12)
        #expect(controller.sessionDetailError == nil)
        #expect(service.requestedSessionIDs == [12, 12, 12])
    }

    @Test func test_loadSessionDetail_when_same_detail_reappears_during_refresh_then_uses_one_request() async {
        // Given
        let service = MockPOSCashSessionService()
        service.sessionToReturn = makeSession(id: 12)
        let controller = POSCashSessionController(service: service)
        let gate = SessionRequestGate()
        service.onSessionRequestedAsync = { _ in await gate.suspend() }
        var firstLoad: Task<Void, Never>?

        // When
        await withCheckedContinuation { continuation in
            gate.started = continuation
            firstLoad = Task { await controller.loadSessionDetail(id: 12) }
        }
        await controller.loadSessionDetail(id: 12)

        // Then
        #expect(service.requestedSessionIDs == [12])
        #expect(controller.isLoadingSessionDetail)
        gate.release?.resume()
        await firstLoad?.value
        #expect(controller.sessionDetail?.id == 12)
        #expect(!controller.isLoadingSessionDetail)
    }

    @Test func test_loadSessionDetail_when_switching_ids_during_refresh_then_ignores_stale_response() async {
        // Given
        let service = MockPOSCashSessionService()
        service.sessionToReturn = makeSession(id: 12)
        let controller = POSCashSessionController(service: service)
        let gate = SessionRequestGate()
        service.onSessionRequestedAsync = { id in
            if id == 12 { await gate.suspend() }
        }
        var firstLoad: Task<Void, Never>?

        // When
        await withCheckedContinuation { continuation in
            gate.started = continuation
            firstLoad = Task { await controller.loadSessionDetail(id: 12) }
        }
        service.sessionToReturn = makeSession(id: 13)
        await controller.loadSessionDetail(id: 13)
        gate.release?.resume()
        await firstLoad?.value

        // Then
        #expect(service.requestedSessionIDs == [12, 13])
        #expect(controller.sessionDetail?.id == 13)
        #expect(!controller.isLoadingSessionDetail)
        #expect(controller.sessionDetailError == nil)
    }

    @Test func test_refreshCurrentSession_when_refund_is_added_then_updates_totals_without_clearing_content() async {
        // Given
        let service = MockPOSCashSessionService()
        service.currentSessionToReturn = POSCashSession(id: 12, openedAt: now, openedBy: "Tester", openingCash: 100,
                                                        movements: [], revision: 1)
        let controller = POSCashSessionController(service: service)
        await controller.loadCurrentSession()
        let refund = POSCashSessionMovement(id: UUID(), kind: .cashRefund, amount: 25, date: now, actor: "Tester",
                                            orderID: 42, refundID: 7, note: nil)
        service.currentSessionToReturn = POSCashSession(id: 12, openedAt: now, openedBy: "Tester", openingCash: 100,
                                                        movements: [refund], revision: 2)
        var visibleCashDuringRefresh: Decimal?
        service.onCurrentSessionRequested = { visibleCashDuringRefresh = controller.currentSession?.expectedCash }

        // When
        await controller.refreshCurrentSession()

        // Then
        #expect(visibleCashDuringRefresh == 100)
        #expect(controller.currentSession?.cashRefunds == 25)
        #expect(controller.currentSession?.expectedCash == 75)
        #expect(controller.currentSession?.revision == 2)
    }

    @Test func test_refreshCurrentSession_when_refund_is_queued_then_retries_it_before_reading_updated_totals() async throws {
        // Given
        let service = MockPOSCashSessionService()
        service.currentSessionToReturn = POSCashSession(id: 12, openedAt: now, openedBy: "Tester", openingCash: 100,
                                                        movements: [], revision: 1)
        let controller = POSCashSessionController(service: service)
        await controller.loadCurrentSession()
        try service.enqueueCashRefund(orderID: 42, refundID: 7, sessionID: 12)
        let refund = POSCashSessionMovement(id: UUID(), kind: .cashRefund, amount: 25, date: now, actor: "Tester",
                                            orderID: 42, refundID: 7, note: nil)
        service.currentSessionToReturn = POSCashSession(id: 12, openedAt: now, openedBy: "Tester", openingCash: 100,
                                                        movements: [refund], revision: 2)
        var pendingDuringRead: Bool?
        service.onCurrentSessionRequested = { pendingDuringRead = service.hasPendingCashMovements }

        // When
        await controller.refreshCurrentSession()

        // Then
        #expect(service.recordedCashRefunds.map { $0.refundID } == [7])
        #expect(service.enqueuedSessionIDs == [12])
        #expect(service.retryCallCount == 2)
        #expect(pendingDuringRead == false)
        #expect(controller.currentSession?.cashRefunds == 25)
        #expect(controller.currentSession?.expectedCash == 75)
    }

    @Test func test_refreshCurrentSession_when_fetch_fails_then_keeps_session_and_shows_retryable_error() async {
        // Given
        let service = MockPOSCashSessionService()
        service.currentSessionToReturn = POSCashSession(id: 12, openedAt: now, openedBy: "Tester", openingCash: 100,
                                                        movements: [], revision: 1)
        let controller = POSCashSessionController(service: service)
        await controller.loadCurrentSession()
        service.currentSessionError = POSCashSessionServiceError.previewUnavailable

        // When
        await controller.refreshCurrentSession()

        // Then
        #expect(controller.currentSession?.id == 12)
        #expect(controller.currentRefreshError != nil)
        #expect(controller.currentLoadError == nil)
        service.currentSessionError = nil
        await controller.refreshCurrentSession()
        #expect(controller.currentRefreshError == nil)
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

    @Test func test_start_when_drawer_is_named_then_starts_session_with_the_drawer_name() async {
        // Given
        let service = MockPOSCashSessionService()
        let controller = POSCashSessionController(service: service, drawerID: { "Front till" })

        // When
        _ = await controller.start(openingCash: 100)

        // Then
        #expect(service.startSessionDrawerIDs == ["Front till"])
    }

    @Test func test_start_when_no_drawer_is_set_up_then_starts_session_without_a_drawer() async {
        // Given
        let service = MockPOSCashSessionService()
        let controller = POSCashSessionController(service: service)

        // When
        _ = await controller.start(openingCash: 100)

        // Then
        #expect(service.startSessionDrawerIDs == [nil])
    }

    private func makeSession(id: Int64) -> POSCashSession {
        .init(id: id, openedAt: now, openedBy: "Tester", openingCash: 0, movements: [], closedAt: now, closedBy: "Tester")
    }
}

@MainActor
private final class SessionRequestGate {
    var started: CheckedContinuation<Void, Never>?
    var release: CheckedContinuation<Void, Never>?

    func suspend() async {
        guard let started else { return }
        self.started = nil
        started.resume()
        await withCheckedContinuation { release = $0 }
    }
}
