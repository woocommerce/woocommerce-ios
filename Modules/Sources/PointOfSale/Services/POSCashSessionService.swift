import Foundation

/// The session boundary for the POS UI. The app supplies a Core API implementation.
@MainActor
public protocol POSCashSessionService {
    var hasPendingCashMovements: Bool { get }
    var isRetryingCashMovements: Bool { get }
    func captureCashSession() async throws -> Int64?
    func enqueueCashSale(orderID: Int64, sessionID: Int64) throws
    func enqueueCashRefund(orderID: Int64, refundID: Int64, sessionID: Int64) throws
    func retryPendingCashMovements() async
    func currentSession() async throws -> POSCashSession?
    func pastSessions(page: Int, perPage: Int) async throws -> POSCashSessionPage
    func session(id: Int64) async throws -> POSCashSession
    func startSession(openingCash: Decimal) async throws -> POSCashSession
    func recordMovement(sessionID: Int64, kind: POSCashSessionMovement.Kind, amount: Decimal, note: String?) async throws -> POSCashSession
    func recordCashSale(orderID: Int64) async throws -> POSCashSession?
    func recordCashRefund(orderID: Int64, refundID: Int64) async throws -> POSCashSession?
    func closeSession(sessionID: Int64, expectedRevision: Int, countedCash: Decimal, note: String?) async throws -> POSCashSession
}

public extension POSCashSessionService {
    var hasPendingCashMovements: Bool { false }
    var isRetryingCashMovements: Bool { false }

    func captureCashSession() async throws -> Int64? {
        do {
            return try await currentSession()?.id
        } catch POSCashSessionServiceError.unsupported {
            return nil
        }
    }

    func retryPendingCashMovements() async {}
}

public struct POSCashSessionPage {
    public let sessions: [POSCashSession]
    public let hasMore: Bool

    public init(sessions: [POSCashSession], hasMore: Bool) {
        self.sessions = sessions
        self.hasMore = hasMore
    }
}

public enum POSCashSessionServiceError: LocalizedError {
    case unsupported
    case sessionAlreadyOpen
    case noOpenSession
    case invalidAmount
    case invalidReference
    case sessionChanged
    case previewUnavailable
    case pendingCashMovements

    public var errorDescription: String? {
        switch self {
        case .unsupported:
            return NSLocalizedString("pos.cashSession.error.updateWooCommerceForCashManagement",
                                     value: "Update WooCommerce to the latest version to use cash management.",
                                     comment: "Error shown when the store's WooCommerce version has no cash session API.")
        case .sessionAlreadyOpen: return NSLocalizedString("pos.cashSession.error.alreadyOpen", value: "A session is already open.", comment: "Cash session error")
        case .noOpenSession: return NSLocalizedString("pos.cashSession.error.noOpenSession", value: "There is no open session.", comment: "Cash session error")
        case .invalidAmount: return NSLocalizedString("pos.cashSession.error.invalidAmount", value: "Enter a valid cash amount.", comment: "Cash session error")
        case .invalidReference:
            return NSLocalizedString("pos.cashSession.error.invalidReference", value: "The cash order reference is invalid.",
                                     comment: "Cash session error")
        case .sessionChanged:
            return NSLocalizedString("pos.cashSession.error.sessionChanged", value: "The session changed. Try again.", comment: "Cash session error")
        case .previewUnavailable:
            return NSLocalizedString("pos.cashSession.error.previewUnavailable", value: "Could not connect to cash sessions. Try again.",
                                     comment: "Cash session preview error")
        case .pendingCashMovements:
            return NSLocalizedString("pos.cashSession.error.pendingCashMovements",
                                     value: "Some cash payments or refunds have not updated the session yet. Retry before closing the session.",
                                     comment: "Shown when cash movements still need to be saved to the store")
        }
    }
}

/// Demo data follows the linked POS prototype. It lives for one POS model lifetime and never
/// writes to the store or the server.
@MainActor
final class POSMockCashSessionService: POSCashSessionService {
    private var openSession: POSCashSession?
    private var closedSessions: [POSCashSession]
    private var nextID: Int64 = 1681895
    private let now: () -> Date
    private let currentActor: String
    private let drawerID: String?
    private let writeDelay: Duration
    private let readDelay: Duration
    private let failCurrentLoad: Bool
    private let isUnsupported: Bool
    private let failPastLoad: Bool
    private let failDetailLoad: Bool
    private let mockCashSaleAmount: Decimal
    private let mockCashRefundAmount: Decimal
    private var recordedSaleOrderIDs: Set<Int64> = []
    private var recordedRefundIDs: Set<Int64> = []

    init(now: @escaping () -> Date = Date.init,
         currentActor: String = "Thomas",
         writeDelay: Duration = .milliseconds(350),
         readDelay: Duration = .zero,
         hasSampleHistory: Bool = true,
         failCurrentLoad: Bool = false,
         isUnsupported: Bool = false,
         failPastLoad: Bool = false,
         failDetailLoad: Bool = false,
         mockCashSaleAmount: Decimal = 24,
         mockCashRefundAmount: Decimal = 12,
         drawerID: String? = nil) {
        self.now = now
        self.currentActor = currentActor
        self.drawerID = drawerID
        self.closedSessions = hasSampleHistory ? Self.sampleSessions() : []
        self.writeDelay = writeDelay
        self.readDelay = readDelay
        self.failCurrentLoad = failCurrentLoad
        self.isUnsupported = isUnsupported
        self.failPastLoad = failPastLoad
        self.failDetailLoad = failDetailLoad
        self.mockCashSaleAmount = mockCashSaleAmount
        self.mockCashRefundAmount = mockCashRefundAmount
    }

    func currentSession() async throws -> POSCashSession? {
        try await Task.sleep(for: readDelay)
        if isUnsupported { throw POSCashSessionServiceError.unsupported }
        if failCurrentLoad { throw POSCashSessionServiceError.previewUnavailable }
        return openSession
    }

    func pastSessions(page: Int, perPage: Int) async throws -> POSCashSessionPage {
        try await Task.sleep(for: readDelay)
        if failPastLoad { throw POSCashSessionServiceError.previewUnavailable }
        let sorted = closedSessions.sorted { ($0.closedAt ?? $0.openedAt) > ($1.closedAt ?? $1.openedAt) }
        let start = max(0, (page - 1) * perPage)
        guard page > 0, perPage > 0, start < sorted.count else {
            return .init(sessions: [], hasMore: false)
        }
        let end = min(start + perPage, sorted.count)
        return .init(sessions: Array(sorted[start..<end]), hasMore: end < sorted.count)
    }

    func session(id: Int64) async throws -> POSCashSession {
        try await Task.sleep(for: readDelay)
        if failDetailLoad { throw POSCashSessionServiceError.previewUnavailable }
        guard let session = closedSessions.first(where: { $0.id == id }) else {
            throw POSCashSessionServiceError.noOpenSession
        }
        return session
    }

    func startSession(openingCash: Decimal) async throws -> POSCashSession {
        try await Task.sleep(for: writeDelay)
        guard openSession == nil else { throw POSCashSessionServiceError.sessionAlreadyOpen }
        guard openingCash >= 0 else { throw POSCashSessionServiceError.invalidAmount }
        let session = POSCashSession(id: nextID, openedAt: now(), openedBy: currentActor,
                                     openingCash: openingCash, movements: [], revision: 0, drawerID: drawerID)
        nextID += 1
        openSession = session
        return session
    }

    func recordMovement(sessionID: Int64, kind: POSCashSessionMovement.Kind, amount: Decimal, note: String?) async throws -> POSCashSession {
        try await Task.sleep(for: writeDelay)
        guard var session = openSession, session.id == sessionID else { throw POSCashSessionServiceError.noOpenSession }
        guard kind == .payIn || kind == .payOut, amount > 0 else { throw POSCashSessionServiceError.invalidAmount }
        session.movements.append(.init(id: UUID(), kind: kind, amount: amount, date: now(),
                                       actor: currentActor, orderID: nil, note: note))
        session.revision += 1
        openSession = session
        return session
    }

    func recordCashSale(orderID: Int64) async throws -> POSCashSession? {
        try await Task.sleep(for: writeDelay)
        guard let session = openSession else { return nil }
        try enqueueCashSale(orderID: orderID, sessionID: session.id)
        return openSession
    }

    func enqueueCashSale(orderID: Int64, sessionID: Int64) throws {
        guard var session = openSession, session.id == sessionID else { throw POSCashSessionServiceError.noOpenSession }
        guard orderID > 0 else { throw POSCashSessionServiceError.invalidReference }
        guard !recordedSaleOrderIDs.contains(orderID) else { return }
        guard mockCashSaleAmount > 0 else { throw POSCashSessionServiceError.invalidAmount }
        session.movements.append(.init(id: UUID(), kind: .cashSale, amount: mockCashSaleAmount, date: now(),
                                       actor: currentActor, orderID: orderID, note: nil))
        session.revision += 1
        recordedSaleOrderIDs.insert(orderID)
        openSession = session
    }

    func recordCashRefund(orderID: Int64, refundID: Int64) async throws -> POSCashSession? {
        try await Task.sleep(for: writeDelay)
        guard let session = openSession else { return nil }
        try enqueueCashRefund(orderID: orderID, refundID: refundID, sessionID: session.id)
        return openSession
    }

    func enqueueCashRefund(orderID: Int64, refundID: Int64, sessionID: Int64) throws {
        guard var session = openSession, session.id == sessionID else { throw POSCashSessionServiceError.noOpenSession }
        guard orderID > 0, refundID > 0 else { throw POSCashSessionServiceError.invalidReference }
        guard !recordedRefundIDs.contains(refundID) else { return }
        guard mockCashRefundAmount > 0 else { throw POSCashSessionServiceError.invalidAmount }
        session.movements.append(.init(id: UUID(), kind: .cashRefund, amount: mockCashRefundAmount, date: now(),
                                       actor: currentActor, orderID: orderID, note: nil))
        session.revision += 1
        recordedRefundIDs.insert(refundID)
        openSession = session
    }

    func closeSession(sessionID: Int64, expectedRevision: Int, countedCash: Decimal, note: String?) async throws -> POSCashSession {
        try await Task.sleep(for: writeDelay)
        guard var session = openSession, session.id == sessionID else { throw POSCashSessionServiceError.noOpenSession }
        guard session.revision == expectedRevision else { throw POSCashSessionServiceError.sessionChanged }
        guard countedCash >= 0 else { throw POSCashSessionServiceError.invalidAmount }
        session.closedAt = now()
        session.closedBy = currentActor
        session.countedCash = countedCash
        session.closingNote = note
        session.revision += 1
        openSession = nil
        closedSessions.insert(session, at: 0)
        return session
    }
}

private extension POSMockCashSessionService {
    static func date(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute)) ?? .distantPast
    }

    static func movement(_ day: Int, _ hour: Int, _ minute: Int, _ kind: POSCashSessionMovement.Kind,
                         _ amount: Decimal, _ actor: String, orderID: Int64? = nil, note: String? = nil) -> POSCashSessionMovement {
        .init(id: UUID(), kind: kind, amount: amount, date: date(day, hour, minute), actor: actor, orderID: orderID, note: note)
    }

    static func sampleSessions() -> [POSCashSession] {
        let first: [POSCashSessionMovement] = [
            movement(14, 9, 12, .cashSale, 36, "Thomas", orderID: 1452),
            movement(14, 9, 58, .cashSale, 22, "Thomas", orderID: 1455),
            movement(14, 10, 31, .cashSale, 89, "Thomas", orderID: 1458),
            movement(14, 11, 5, .payOut, 30, "Thomas", note: "Window cleaner"),
            movement(14, 11, 44, .cashSale, 46, "Thomas", orderID: 1461),
            movement(14, 12, 20, .cashRefund, 89, "Maria", orderID: 1458),
            movement(14, 13, 2, .cashSale, 54, "Maria", orderID: 1466),
            movement(14, 13, 35, .payIn, 100, "Maria", note: "Change order from bank"),
            movement(14, 14, 18, .cashSale, 18, "Maria", orderID: 1470),
            movement(14, 15, 3, .cashSale, 68, "Maria", orderID: 1473),
            movement(14, 16, 27, .cashSale, 42, "Maria", orderID: 1478),
            movement(14, 17, 10, .payOut, Decimal(string: "27.50") ?? 0, "Maria", note: "Staff lunch")
        ]
        let second: [POSCashSessionMovement] = [
            movement(13, 11, 20, .cashSale, 24, "Maria", orderID: 1441),
            movement(13, 12, 55, .cashSale, 42, "Maria", orderID: 1444),
            movement(13, 14, 10, .cashSale, 12, "Maria", orderID: 1447)
        ]
        let third: [POSCashSessionMovement] = [
            movement(12, 9, 5, .cashSale, 58, "Thomas", orderID: 1402),
            movement(12, 9, 47, .cashSale, 24, "Thomas", orderID: 1405),
            movement(12, 10, 22, .cashSale, 112, "Thomas", orderID: 1408),
            movement(12, 10, 58, .cashRefund, 24, "Thomas", orderID: 1405),
            movement(12, 11, 33, .cashSale, 36, "Thomas", orderID: 1412),
            movement(12, 12, 0, .payIn, 80, "Thomas", note: "Float top-up from safe"),
            movement(12, 12, 41, .cashSale, 68, "Thomas", orderID: 1417),
            movement(12, 13, 29, .cashSale, 42, "Thomas", orderID: 1420),
            movement(12, 14, 15, .cashRefund, 36, "Thomas", orderID: 1412),
            movement(12, 15, 8, .cashSale, 89, "Thomas", orderID: 1426),
            movement(12, 16, 0, .payOut, 15, "Thomas", note: "Parking for delivery van"),
            movement(12, 17, 12, .cashSale, 18, "Thomas", orderID: 1432),
            movement(12, 18, 30, .cashSale, 54, "Thomas", orderID: 1437)
        ]
        let fourth: [POSCashSessionMovement] = [
            movement(11, 11, 52, .cashSale, 42, "Maria", orderID: 1388),
            movement(11, 12, 38, .cashSale, 28, "Maria", orderID: 1391),
            movement(11, 13, 15, .payOut, 10, "Maria", note: "Petty cash for stamps"),
            movement(11, 14, 44, .cashSale, 68, "Maria", orderID: 1395),
            movement(11, 15, 30, .cashSale, 24, "Maria", orderID: 1398),
            movement(11, 16, 10, .payIn, 25, "Thomas", note: "Change order from bank"),
            movement(11, 17, 5, .cashSale, 18, "Maria", orderID: 1400)
        ]
        return [
            .init(id: 1681891, openedAt: date(14, 8, 45), openedBy: "Thomas", openingCash: 200, movements: first,
                  closedAt: date(14, 18, 12), closedBy: "Maria", countedCash: Decimal(string: "523.50"),
                  revision: first.count + 1, drawerID: "Front counter"),
            .init(id: 1681884, openedAt: date(13, 10, 0), openedBy: "Maria", openingCash: 100, movements: second,
                  closedAt: date(13, 15, 0), closedBy: "Maria", countedCash: 178, revision: second.count + 1),
            .init(id: 1681877, openedAt: date(12, 8, 30), openedBy: "Thomas", openingCash: 250, movements: third,
                  closedAt: date(12, 19, 4), closedBy: "Thomas", countedCash: 758, revision: third.count + 1),
            .init(id: 1681869, openedAt: date(11, 11, 15), openedBy: "Maria", openingCash: 80, movements: fourth,
                  closedAt: date(11, 18, 0), closedBy: "Maria", countedCash: 275, revision: fourth.count + 1)
        ]
    }
}
