import Testing
import Foundation
import enum Yosemite.PrinterError
@testable import PointOfSale

@MainActor
struct POSCashDrawerControllerTests {
    private let userDefaults: UserDefaults
    private let date = Date(timeIntervalSince1970: 1_000)

    init() throws {
        userDefaults = try #require(UserDefaults(suiteName: UUID().uuidString))
    }

    @Test func test_open_when_drawer_opens_then_returns_opened_and_reports_event() async {
        // Given
        let service = MockCashDrawerService()
        let sut = makeController(service: service)
        var reportedEvents: [POSCashDrawerEvent] = []
        sut.onDrawerEvent = { reportedEvents.append($0) }

        // When
        let result = await sut.open(for: .noSale)

        // Then
        let expectedEvent = POSCashDrawerEvent(reason: .noSale, result: .opened, date: date)
        #expect(result == .opened)
        #expect(sut.lastEvent == expectedEvent)
        #expect(reportedEvents == [expectedEvent])
    }

    @Test func test_open_when_printer_not_connected_then_returns_notConnected() async {
        // Given
        let service = MockCashDrawerService()
        service.openError = PrinterError.printerNotConnected
        let sut = makeController(service: service)

        // When
        let result = await sut.open(for: .test)

        // Then
        #expect(result == .notConnected)
        #expect(sut.lastEvent?.result == .notConnected)
    }

    @Test func test_open_when_command_fails_then_returns_failed() async {
        // Given
        let service = MockCashDrawerService()
        service.openError = NSError(domain: "test", code: 1)
        let sut = makeController(service: service)

        // When
        let result = await sut.open(for: .cashRefund)

        // Then
        #expect(result == .failed)
    }

    @Test func test_open_when_printer_returns_later_then_event_uses_attempt_time() async {
        // Given
        let service = MockCashDrawerService()
        var clock = date
        let sut = POSCashDrawerController(service: service, userDefaults: userDefaults, now: { clock })
        sut.sessionSnapshot = { POSCashDrawerSessionSnapshot(id: 123, drawerID: "Front till") }
        service.onOpen = { clock = date.addingTimeInterval(60) }

        // When
        await sut.open(for: .noSale)

        // Then
        #expect(sut.lastEvent?.date == date)
    }

    @Test func test_openAutomatically_when_automatic_opening_on_then_opens_for_the_given_reason() async {
        // Given
        let service = MockCashDrawerService()
        let sut = makeController(service: service)

        // When
        await sut.openAutomatically(for: .cashRefund, sessionID: 123)

        // Then
        #expect(service.openCallCount == 1)
        #expect(sut.lastEvent?.reason == .cashRefund)
    }

    @Test func test_openAutomatically_when_automatic_opening_off_then_does_not_open() async {
        // Given
        let service = MockCashDrawerService()
        let sut = makeController(service: service)
        sut.opensAutomaticallyForCashPayments = false

        // When
        await sut.openAutomatically(for: .cashSale)

        // Then
        #expect(service.openCallCount == 0)
        #expect(sut.lastEvent == nil)
    }

    @Test func test_opensAutomaticallyForCashPayments_when_changed_then_persists_across_controllers() {
        // Given
        let sut = makeController(service: MockCashDrawerService())
        #expect(sut.opensAutomaticallyForCashPayments)

        // When
        sut.opensAutomaticallyForCashPayments = false

        // Then
        #expect(makeController(service: MockCashDrawerService()).opensAutomaticallyForCashPayments == false)
    }

    @Test func test_updateDrawerName_when_name_has_surrounding_whitespace_then_saves_trimmed_name() {
        // Given
        let sut = makeController(service: MockCashDrawerService())

        // When
        sut.updateDrawerName("  Front till \n")

        // Then
        #expect(sut.drawerName == "Front till")
        #expect(makeController(service: MockCashDrawerService()).drawerName == "Front till")
    }

    @Test func test_updateDrawerName_when_name_is_blank_then_clears_the_name() {
        // Given
        let sut = makeController(service: MockCashDrawerService())
        sut.updateDrawerName("Front till")

        // When
        sut.updateDrawerName("   ")

        // Then
        #expect(sut.drawerName == nil)
        #expect(makeController(service: MockCashDrawerService()).drawerName == nil)
    }

    @Test func test_open_when_drawer_is_named_then_records_open_requested_event_in_session() async {
        // Given
        let sessionService = MockPOSCashSessionService()
        let sut = makeController(service: MockCashDrawerService(), sessionService: sessionService)
        sut.updateDrawerName("Front till")

        // When
        let recorded = await withCheckedContinuation { continuation in
            sessionService.onDrawerEventRecorded = { continuation.resume(returning: $0) }
            Task { await sut.open(for: .cashSale, orderID: 42) }
        }

        // Then
        #expect(recorded.outcome == .openRequested)
        #expect(recorded.reason == .cashSale)
        #expect(recorded.orderID == 42)
        #expect(recorded.occurredAt == date)
        #expect(recorded.correlationID != nil)
        #expect(sessionService.recordedDrawerEventSessionIDs == [123])
    }

    @Test func test_open_when_printer_not_connected_then_records_open_failed_event_in_session() async {
        // Given
        let drawerService = MockCashDrawerService()
        drawerService.openError = PrinterError.printerNotConnected
        let sessionService = MockPOSCashSessionService()
        let sut = makeController(service: drawerService, sessionService: sessionService)
        sut.updateDrawerName("Front till")

        // When
        let recorded = await withCheckedContinuation { continuation in
            sessionService.onDrawerEventRecorded = { continuation.resume(returning: $0) }
            Task { await sut.open(for: .noSale) }
        }

        // Then
        #expect(recorded.outcome == .openFailed)
        #expect(recorded.reason == .noSale)
        #expect(recorded.orderID == nil)
        #expect(sessionService.recordedDrawerEventSessionIDs == [123])
    }

    @Test func test_noSale_when_session_changes_during_drawer_command_then_records_in_captured_session() async {
        // Given
        let drawerService = MockCashDrawerService()
        let sessionService = MockPOSCashSessionService()
        let sut = makeController(service: drawerService, sessionService: sessionService)
        sut.updateDrawerName("Front till")
        drawerService.onOpen = { sessionService.capturedSessionID = 456 }

        // When
        let recorded = await withCheckedContinuation { continuation in
            sessionService.onDrawerEventRecorded = { continuation.resume(returning: $0) }
            Task { await sut.open(for: .noSale) }
        }

        // Then
        #expect(recorded.reason == .noSale)
        #expect(sessionService.recordedDrawerEventSessionIDs == [123])
        #expect(sessionService.captureCallCount == 0)
    }

    @Test func test_noSale_when_cash_management_has_not_loaded_then_reads_session_before_drawer_opens() async {
        // Given
        let drawerService = MockCashDrawerService()
        let sessionService = MockPOSCashSessionService()
        sessionService.currentSessionToReturn = POSCashSession(id: 123, openedAt: date, openedBy: "Cashier",
                                                              openingCash: 0, movements: [], drawerID: "Front till")
        let sut = makeController(service: drawerService, sessionService: sessionService)
        sut.sessionSnapshot = nil
        drawerService.onOpen = { sessionService.currentSessionToReturn = nil }

        // When
        let recorded = await withCheckedContinuation { continuation in
            sessionService.onDrawerEventRecorded = { continuation.resume(returning: $0) }
            Task { await sut.open(for: .noSale) }
        }

        // Then
        #expect(recorded.reason == .noSale)
        #expect(sessionService.recordedDrawerEventSessionIDs == [123])
    }

    @Test func test_testOpen_when_session_service_is_slow_then_returns_without_network_lookup() async {
        // Given
        let drawerService = MockCashDrawerService()
        let sessionService = MockPOSCashSessionService()
        let sut = makeController(service: drawerService, sessionService: sessionService)
        sut.updateDrawerName("Front till")

        // When
        let result = await sut.open(for: .test)

        // Then
        #expect(result == .opened)
        #expect(drawerService.openCallCount == 1)
        #expect(sessionService.captureCallCount == 0)
    }

    @Test func test_noSale_when_drawer_name_changes_then_uses_session_binding() async {
        // Given
        let sessionService = MockPOSCashSessionService()
        let sut = makeController(service: MockCashDrawerService(), sessionService: sessionService)
        sut.sessionSnapshot = { POSCashDrawerSessionSnapshot(id: 123, drawerID: "Front till") }
        sut.updateDrawerName("Back room")

        // When
        let recorded = await withCheckedContinuation { continuation in
            sessionService.onDrawerEventRecorded = { continuation.resume(returning: $0) }
            Task { await sut.open(for: .noSale) }
        }

        // Then
        #expect(recorded.reason == .noSale)
        #expect(sessionService.recordedDrawerEventSessionIDs == [123])
    }

    @Test func test_noSale_when_session_has_no_bound_drawer_then_skips_event_despite_new_name() async {
        // Given
        let sessionService = MockPOSCashSessionService()
        let sut = makeController(service: MockCashDrawerService(), sessionService: sessionService)
        sut.sessionSnapshot = { POSCashDrawerSessionSnapshot(id: 123, drawerID: nil) }
        sut.updateDrawerName("Front till")

        // When
        let result = await sut.open(for: .noSale)

        // Then
        #expect(result == .opened)
        #expect(sessionService.recordedDrawerEvents.isEmpty)
    }

    @Test func test_automatic_open_when_payment_has_no_session_then_does_not_attach_event_to_later_session() async {
        // Given
        let sessionService = MockPOSCashSessionService()
        let drawerService = MockCashDrawerService()
        let sut = makeController(service: drawerService, sessionService: sessionService)
        sut.updateDrawerName("Front till")

        // When
        await sut.openAutomatically(for: .cashSale, orderID: 42, sessionID: nil)

        // Then
        #expect(sessionService.captureCallCount == 0)
        #expect(sessionService.recordedDrawerEvents.isEmpty)
        #expect(drawerService.openCallCount == 0)
    }

    @Test func test_open_when_no_session_then_does_not_open_drawer() async {
        // Given
        let drawerService = MockCashDrawerService()
        let sut = makeController(service: drawerService)
        sut.sessionSnapshot = { nil }

        // When
        let noSaleResult = await sut.open(for: .noSale)
        let testResult = await sut.open(for: .test)

        // Then
        #expect(noSaleResult == .noSession)
        #expect(testResult == .noSession)
        #expect(drawerService.openCallCount == 0)
        #expect(sut.lastEvent == nil)
    }

    @Test func test_openBeforeSession_when_no_session_then_opens_drawer_without_recording_event() async {
        // Given
        let drawerService = MockCashDrawerService()
        let sessionService = MockPOSCashSessionService()
        sessionService.capturedSessionID = nil
        let sut = makeController(service: drawerService, sessionService: sessionService)

        // When
        let result = await sut.openBeforeSession()

        // Then
        #expect(result == .opened)
        #expect(drawerService.openCallCount == 1)
        #expect(sessionService.recordedDrawerEvents.isEmpty)
    }

    @Test func test_automatic_refund_open_when_session_changes_then_uses_refund_session() async {
        // Given
        let sessionService = MockPOSCashSessionService()
        sessionService.capturedSessionID = 456
        let sut = makeController(service: MockCashDrawerService(), sessionService: sessionService)
        sut.updateDrawerName("Front till")

        // When
        let recorded = await withCheckedContinuation { continuation in
            sessionService.onDrawerEventRecorded = { continuation.resume(returning: $0) }
            Task { await sut.openAutomatically(for: .cashRefund, orderID: 42, sessionID: 123) }
        }

        // Then
        #expect(recorded.reason == .cashRefund)
        #expect(sessionService.recordedDrawerEventSessionIDs == [123])
        #expect(sessionService.captureCallCount == 0)
    }

    @Test func test_handleDrawerSignal_when_signal_changes_after_app_open_then_learns_open_value_and_records_linked_opened_event() async {
        // Given
        let sessionService = MockPOSCashSessionService()
        let sut = makeController(service: MockCashDrawerService(), sessionService: sessionService)
        sut.updateDrawerName("Front till")

        // When
        let recorded = await recordedEvents(count: 2, from: sessionService) {
            await sut.open(for: .cashSale, orderID: 42)
            sut.handleDrawerSignal(false)
        }

        // Then
        let requested = recorded[0]
        let opened = recorded[1]
        #expect(sut.openSignal == false)
        #expect(requested.outcome == .openRequested)
        #expect(opened.outcome == .opened)
        #expect(opened.reason == .cashSale)
        #expect(opened.orderID == 42)
        #expect(opened.correlationID == requested.correlationID)
        #expect(sessionService.recordedDrawerEventSessionIDs == [123, 123])
    }

    @Test func test_handleDrawerSignal_when_drawer_opens_without_app_request_then_records_unknown_opened_event() async {
        // Given
        let sessionService = MockPOSCashSessionService()
        let sut = makeController(service: MockCashDrawerService(), sessionService: sessionService)
        sut.updateDrawerName("Front till")
        let learned = await recordedEvents(count: 2, from: sessionService) {
            await sut.open(for: .test)
            sut.handleDrawerSignal(true)
        }
        #expect(learned.count == 2)
        sut.handleDrawerSignal(false)

        // When
        let recorded = await recordedEvents(count: 1, from: sessionService) {
            sut.handleDrawerSignal(true)
        }

        // Then
        #expect(recorded.first?.outcome == .opened)
        #expect(recorded.first?.reason == .unknown)
        #expect(recorded.first?.correlationID == nil)
    }

    @Test func test_handleDrawerSignal_when_open_value_is_unknown_and_no_app_open_then_does_not_record() {
        // Given
        let sessionService = MockPOSCashSessionService()
        let sut = makeController(service: MockCashDrawerService(), sessionService: sessionService)
        sut.updateDrawerName("Front till")

        // When
        sut.handleDrawerSignal(true)

        // Then
        #expect(sut.openSignal == nil)
        #expect(sessionService.recordedDrawerEvents.isEmpty)
    }

    @Test func test_open_when_drawer_is_not_named_then_does_not_record_event_in_session() async {
        // Given
        let sessionService = MockPOSCashSessionService()
        let sut = makeController(service: MockCashDrawerService(), sessionService: sessionService)

        // When
        await sut.open(for: .test)

        // Then
        #expect(sessionService.recordedDrawerEvents.isEmpty)
    }
}

private extension POSCashDrawerControllerTests {
    /// Runs `actions`, then waits until the session service has recorded `count` more drawer events.
    func recordedEvents(count: Int,
                        from sessionService: MockPOSCashSessionService,
                        actions: @escaping @Sendable @MainActor () async -> Void) async -> [POSCashDrawerEventRecord] {
        await withCheckedContinuation { continuation in
            var events: [POSCashDrawerEventRecord] = []
            sessionService.onDrawerEventRecorded = { event in
                events.append(event)
                if events.count == count {
                    sessionService.onDrawerEventRecorded = nil
                    continuation.resume(returning: events)
                }
            }
            Task { await actions() }
        }
    }

    func makeController(service: MockCashDrawerService,
                        sessionService: MockPOSCashSessionService? = nil) -> POSCashDrawerController {
        let controller = POSCashDrawerController(service: service, sessionService: sessionService,
                                                 userDefaults: userDefaults, now: { [date] in date })
        controller.sessionSnapshot = { [weak controller, weak sessionService] in
            guard let controller else { return nil }
            if let sessionService {
                guard let id = sessionService.capturedSessionID else { return nil }
                return POSCashDrawerSessionSnapshot(id: id, drawerID: controller.drawerName)
            }
            return POSCashDrawerSessionSnapshot(id: 123, drawerID: controller.drawerName)
        }
        return controller
    }
}
