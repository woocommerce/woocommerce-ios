import Foundation

public protocol POSCashSessionRemoteProtocol {
    func listSessions(siteID: Int64, deviceID: String?, status: String, page: Int, perPage: Int) async throws -> PagedItems<POSCashSessionResponse>
    func session(siteID: Int64, id: Int64) async throws -> POSCashSessionResponse
    func movements(siteID: Int64, sessionID: Int64, page: Int, perPage: Int) async throws -> PagedItems<POSCashMovementResponse>
    func openSession(siteID: Int64, requestID: UUID, deviceID: String, openingAmount: String) async throws -> POSCashSessionResponse
    func recordMovement(siteID: Int64, sessionID: Int64, requestID: UUID, type: String,
                        amount: String, reason: String) async throws -> POSCashMovementResponse
    func recordCashSale(siteID: Int64, sessionID: Int64, requestID: UUID, orderID: Int64) async throws -> POSCashMovementResponse
    func recordCashRefund(siteID: Int64, sessionID: Int64, requestID: UUID, orderID: Int64,
                          refundID: Int64) async throws -> POSCashMovementResponse
    func closeSession(siteID: Int64, sessionID: Int64, requestID: UUID, expectedRevision: Int,
                      countedAmount: String, note: String?) async throws -> POSCashSessionResponse
}

/// WooCommerce POS cash-session endpoints. The existing Network chooses direct REST with an
/// application password when available and otherwise uses the Jetpack request path.
public final class POSCashSessionRemote: Remote, POSCashSessionRemoteProtocol {
    public func listSessions(siteID: Int64, deviceID: String?, status: String, page: Int, perPage: Int) async throws -> PagedItems<POSCashSessionResponse> {
        var parameters: RequestParameterConvertibleDictionary = [
            "status": status,
            "page": page,
            "per_page": perPage
        ]
        if let deviceID { parameters["device_id"] = deviceID }
        let request = JetpackRequest(wooApiVersion: .wcPosV1, method: .get, siteID: siteID,
                                     path: Path.sessions, parameters: parameters, availableAsRESTRequest: true)
        let response = try await enqueueWithResponseHeaders(request, mapper: ListMapper<POSCashSessionResponse>(siteID: siteID))
        return createPagedItems(items: response.data, responseHeaders: response.headers, currentPageNumber: page)
    }

    public func session(siteID: Int64, id: Int64) async throws -> POSCashSessionResponse {
        let request = JetpackRequest(wooApiVersion: .wcPosV1, method: .get, siteID: siteID,
                                     path: "\(Path.sessions)/\(id)", availableAsRESTRequest: true)
        return try await enqueue(request, mapper: SingleItemMapper<POSCashSessionResponse>(siteID: siteID))
    }

    public func movements(siteID: Int64, sessionID: Int64, page: Int, perPage: Int) async throws -> PagedItems<POSCashMovementResponse> {
        let request = JetpackRequest(wooApiVersion: .wcPosV1, method: .get, siteID: siteID,
                                     path: "\(Path.sessions)/\(sessionID)/movements",
                                     parameters: ["page": page, "per_page": perPage], availableAsRESTRequest: true)
        let response = try await enqueueWithResponseHeaders(request, mapper: ListMapper<POSCashMovementResponse>(siteID: siteID))
        return createPagedItems(items: response.data, responseHeaders: response.headers, currentPageNumber: page)
    }

    public func openSession(siteID: Int64, requestID: UUID, deviceID: String, openingAmount: String) async throws -> POSCashSessionResponse {
        let request = JetpackRequest(wooApiVersion: .wcPosV1, method: .post, siteID: siteID,
                                     path: Path.sessions,
                                     parameters: ["request_id": requestID.uuidString,
                                                  "device_id": deviceID,
                                                  "opening_amount": openingAmount],
                                     availableAsRESTRequest: true)
        return try await enqueue(request, mapper: SingleItemMapper<POSCashSessionResponse>(siteID: siteID))
    }

    public func recordMovement(siteID: Int64, sessionID: Int64, requestID: UUID, type: String,
                               amount: String, reason: String) async throws -> POSCashMovementResponse {
        let request = JetpackRequest(wooApiVersion: .wcPosV1, method: .post, siteID: siteID,
                                     path: "\(Path.sessions)/\(sessionID)/movements",
                                     parameters: ["request_id": requestID.uuidString, "type": type,
                                                  "amount": amount, "reason": reason],
                                     availableAsRESTRequest: true)
        return try await enqueue(request, mapper: SingleItemMapper<POSCashMovementResponse>(siteID: siteID))
    }

    public func recordCashSale(siteID: Int64, sessionID: Int64, requestID: UUID, orderID: Int64) async throws -> POSCashMovementResponse {
        let parameters: RequestParameterConvertibleDictionary = [
            "request_id": requestID.uuidString,
            "type": "cash_sale",
            "order_id": orderID
        ]
        let request = JetpackRequest(wooApiVersion: .wcPosV1, method: .post, siteID: siteID,
                                     path: "\(Path.sessions)/\(sessionID)/movements",
                                     parameters: parameters, availableAsRESTRequest: true)
        return try await enqueue(request, mapper: SingleItemMapper<POSCashMovementResponse>(siteID: siteID))
    }

    public func recordCashRefund(siteID: Int64, sessionID: Int64, requestID: UUID, orderID: Int64,
                                 refundID: Int64) async throws -> POSCashMovementResponse {
        let parameters: RequestParameterConvertibleDictionary = [
            "request_id": requestID.uuidString,
            "type": "cash_refund",
            "order_id": orderID,
            "refund_id": refundID
        ]
        let request = JetpackRequest(wooApiVersion: .wcPosV1, method: .post, siteID: siteID,
                                     path: "\(Path.sessions)/\(sessionID)/movements",
                                     parameters: parameters, availableAsRESTRequest: true)
        return try await enqueue(request, mapper: SingleItemMapper<POSCashMovementResponse>(siteID: siteID))
    }

    public func closeSession(siteID: Int64, sessionID: Int64, requestID: UUID, expectedRevision: Int,
                             countedAmount: String, note: String?) async throws -> POSCashSessionResponse {
        var parameters: RequestParameterConvertibleDictionary = [
            "request_id": requestID.uuidString,
            "expected_revision": expectedRevision,
            "counted_amount": countedAmount
        ]
        if let note { parameters["note"] = note }
        let request = JetpackRequest(wooApiVersion: .wcPosV1, method: .post, siteID: siteID,
                                     path: "\(Path.sessions)/\(sessionID)/close",
                                     parameters: parameters, availableAsRESTRequest: true)
        return try await enqueue(request, mapper: SingleItemMapper<POSCashSessionResponse>(siteID: siteID))
    }
}

private extension POSCashSessionRemote {
    enum Path {
        static let sessions = "cash-sessions"
    }
}
