import Foundation
import Testing
@testable import PointOfSale

@MainActor
struct POSMockCashSessionServiceTests {
    @Test func test_cash_order_events_when_session_is_open_then_update_totals_once_per_reference() async throws {
        // Given
        let service = POSMockCashSessionService(writeDelay: .zero, hasSampleHistory: false,
                                                mockCashSaleAmount: 24, mockCashRefundAmount: 12)
        #expect(try await service.recordCashSale(orderID: 42) == nil)
        #expect(try await service.recordCashRefund(orderID: 42, refundID: 7) == nil)
        _ = try await service.startSession(openingCash: 100)

        // When
        _ = try await service.recordCashSale(orderID: 42)
        _ = try await service.recordCashSale(orderID: 42)
        _ = try await service.recordCashRefund(orderID: 42, refundID: 7)
        let session = try #require(try await service.recordCashRefund(orderID: 42, refundID: 7))

        // Then
        #expect(session.cashSales == 24)
        #expect(session.cashRefunds == 12)
        #expect(session.expectedCash == 112)
        #expect(session.movements.count == 2)
        #expect(session.revision == 2)
    }
}
