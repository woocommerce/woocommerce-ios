import Combine
import Foundation
import Networking
import NetworkingCore

public typealias POSCashSessionResponse = Networking.POSCashSessionResponse
public typealias POSCashMovementResponse = Networking.POSCashMovementResponse
public typealias POSCashSessionSite = NetworkingCore.JetpackSite

/// Store API access for cash management. App adaptors depend on this Yosemite boundary.
public final class POSCashSessionRemoteService {
    private let remote: POSCashSessionRemoteProtocol

    public init(remote: POSCashSessionRemoteProtocol) {
        self.remote = remote
    }

    public convenience init?(credentials: Credentials?,
                             selectedSite: AnyPublisher<POSCashSessionSite?, Never>,
                             appPasswordSupportState: AnyPublisher<Bool, Never>) {
        guard let credentials else { return nil }
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        self.init(remote: POSCashSessionRemote(network: network))
    }

    public func listSessions(siteID: Int64, deviceID: String?, status: String, page: Int, perPage: Int) async throws -> PagedItems<POSCashSessionResponse> {
        try await perform { try await remote.listSessions(siteID: siteID, deviceID: deviceID, status: status, page: page, perPage: perPage) }
    }

    public func session(siteID: Int64, id: Int64) async throws -> POSCashSessionResponse {
        try await perform { try await remote.session(siteID: siteID, id: id) }
    }

    public func movements(siteID: Int64, sessionID: Int64, page: Int, perPage: Int) async throws -> PagedItems<POSCashMovementResponse> {
        try await perform { try await remote.movements(siteID: siteID, sessionID: sessionID, page: page, perPage: perPage) }
    }

    public func openSession(siteID: Int64, requestID: UUID, deviceID: String, openingAmount: String) async throws -> POSCashSessionResponse {
        try await perform { try await remote.openSession(siteID: siteID, requestID: requestID, deviceID: deviceID, openingAmount: openingAmount) }
    }

    public func recordMovement(siteID: Int64, sessionID: Int64, requestID: UUID, type: String,
                               amount: String, reason: String) async throws -> POSCashMovementResponse {
        try await perform { try await remote.recordMovement(siteID: siteID, sessionID: sessionID, requestID: requestID,
                                             type: type, amount: amount, reason: reason) }
    }

    public func recordCashSale(siteID: Int64, sessionID: Int64, requestID: UUID, orderID: Int64) async throws -> POSCashMovementResponse {
        try await perform { try await remote.recordCashSale(siteID: siteID, sessionID: sessionID, requestID: requestID, orderID: orderID) }
    }

    public func recordCashRefund(siteID: Int64, sessionID: Int64, requestID: UUID, orderID: Int64, refundID: Int64) async throws -> POSCashMovementResponse {
        try await perform { try await remote.recordCashRefund(siteID: siteID, sessionID: sessionID, requestID: requestID, orderID: orderID, refundID: refundID) }
    }

    public func closeSession(siteID: Int64, sessionID: Int64, requestID: UUID, expectedRevision: Int,
                             countedAmount: String, note: String?) async throws -> POSCashSessionResponse {
        try await perform { try await remote.closeSession(siteID: siteID, sessionID: sessionID, requestID: requestID,
                                           expectedRevision: expectedRevision, countedAmount: countedAmount, note: note) }
    }

    private func perform<Value>(_ operation: () async throws -> Value) async throws -> Value {
        do {
            return try await operation()
        } catch let error as NetworkError {
            throw POSCashSessionAPIError(statusCode: error.responseCode, code: error.errorCode,
                                          recordedSessionID: (error.errorData?["session_id"]?.value as? Int).map(Int64.init))
        } catch DotcomError.noRestRoute {
            throw POSCashSessionAPIError(statusCode: 404, code: "rest_no_route")
        } catch let error as DotcomError {
            guard case let .unknown(code, _, data) = error else { throw error }
            throw POSCashSessionAPIError(statusCode: data?["status"]?.value as? Int, code: code,
                                          recordedSessionID: (data?["session_id"]?.value as? Int).map(Int64.init))
        }
    }
}

/// Transport-independent information needed to recover cash session operations.
public struct POSCashSessionAPIError: Error {
    public let statusCode: Int?
    public let code: String?
    public let recordedSessionID: Int64?

    public init(statusCode: Int?, code: String?, recordedSessionID: Int64? = nil) {
        self.statusCode = statusCode
        self.code = code
        self.recordedSessionID = recordedSessionID
    }
}
