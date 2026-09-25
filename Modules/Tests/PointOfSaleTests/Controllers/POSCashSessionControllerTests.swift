import Foundation
import Testing
@testable import PointOfSale

@MainActor
struct POSCashSessionControllerTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

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
}
