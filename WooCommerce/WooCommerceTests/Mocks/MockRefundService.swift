import Foundation
import Yosemite

/// Mock implementation of `RefundServiceProtocol` for unit tests.
///
final class MockRefundService: RefundServiceProtocol {
    enum MockError: Error {
        case notStubbed
    }

    // Stub return values
    var previewRefundResult: Result<RefundPreview, Error>?
    var createRefundResult: Result<Refund, Error>?

    // Spy properties for verification
    private(set) var previewRefundCallCount = 0
    private(set) var spyCreateRefundRestockItems: Bool?

    func previewRefund(siteID: Int64,
                       orderID: Int64,
                       lineItems: [RefundV4LineItem]) async throws -> RefundPreview {
        previewRefundCallCount += 1
        switch previewRefundResult {
        case .success(let preview):
            return preview
        case .failure(let error):
            throw error
        case nil:
            throw MockError.notStubbed
        }
    }

    func createRefund(siteID: Int64,
                      orderID: Int64,
                      reason: String,
                      automaticRefund: Bool,
                      restockItems: Bool,
                      lineItems: [RefundV4LineItem]) async throws -> Refund {
        spyCreateRefundRestockItems = restockItems
        switch createRefundResult {
        case .success(let refund):
            return refund
        case .failure(let error):
            throw error
        case nil:
            throw MockError.notStubbed
        }
    }

    func previewRefund(siteID: Int64,
                       orderID: Int64,
                       lineItems: [RefundPreviewLineItem]) async throws -> RefundPreview {
        previewRefundCallCount += 1
        switch previewRefundResult {
        case .success(let preview):
            return preview
        case .failure(let error):
            throw error
        case nil:
            throw MockError.notStubbed
        }
    }

    func createRefund(siteID: Int64,
                      orderID: Int64,
                      reason: String,
                      automaticRefund: Bool,
                      restockItems: Bool,
                      amountOverride: String?,
                      lineItems: [ComputedRefundLineItem]) async throws -> Refund {
        spyCreateRefundRestockItems = restockItems
        switch createRefundResult {
        case .success(let refund):
            return refund
        case .failure(let error):
            throw error
        case nil:
            throw MockError.notStubbed
        }
    }
}
