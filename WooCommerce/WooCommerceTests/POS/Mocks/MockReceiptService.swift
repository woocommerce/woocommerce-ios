import Foundation
@testable import Yosemite

class MockReceiptService: POSReceiptServiceProtocol {
    func sendReceipt(order: Yosemite.Order, recipientEmail: String) async throws {
        // no-op
    }
}
