import Foundation
@testable import PointOfSale

final class MockPOSScanToPayHandler: POSScanToPayHandling {
    var completeScanToPayPaymentCalled = false
    var errorToThrow: Error?

    func completeScanToPayPayment() async throws {
        completeScanToPayPaymentCalled = true
        if let error = errorToThrow { throw error }
    }

    var recordScanToPayPaymentMethodCalled = false
    var onRecordScanToPayPaymentMethodCalled: (@Sendable () -> Void)?

    func recordScanToPayPaymentMethod() async {
        recordScanToPayPaymentMethodCalled = true
        onRecordScanToPayPaymentMethodCalled?()
    }
}
