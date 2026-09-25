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

    @Test func test_openAutomatically_when_automatic_opening_on_then_opens_for_the_given_reason() async {
        // Given
        let service = MockCashDrawerService()
        let sut = makeController(service: service)

        // When
        await sut.openAutomatically(for: .cashRefund)

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
}

private extension POSCashDrawerControllerTests {
    func makeController(service: MockCashDrawerService) -> POSCashDrawerController {
        POSCashDrawerController(service: service, userDefaults: userDefaults, now: { [date] in date })
    }
}
