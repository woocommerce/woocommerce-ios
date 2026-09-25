import Foundation

/// A confirmed cash transaction awaiting acknowledgement from its original session.
public struct POSCashEvent: Codable, Equatable, Sendable {
    public enum Source: Codable, Equatable, Sendable {
        case sale(orderID: Int64)
        case refund(orderID: Int64, refundID: Int64)
    }

    public let requestID: UUID
    public let siteID: Int64
    public let sessionID: Int64
    public let source: Source
}

@MainActor
public protocol POSCashEventJournal {
    func load() throws -> [POSCashEvent]
    func save(_ events: [POSCashEvent]) throws
}

/// Writes the complete queue atomically before a payment reports success.
@MainActor
public final class POSCashEventFileJournal: POSCashEventJournal {
    private let fileURL: URL

    public init(siteID: Int64, deviceID: String, directoryURL: URL = URL.applicationSupportDirectory) {
        self.fileURL = directoryURL.appendingPathComponent("POSCashEvents", isDirectory: true)
            .appendingPathComponent(String(siteID), isDirectory: true)
            .appendingPathComponent(deviceID).appendingPathExtension("json")
    }

    public func load() throws -> [POSCashEvent] {
        do {
            return try JSONDecoder().decode([POSCashEvent].self, from: Data(contentsOf: fileURL))
        } catch CocoaError.fileReadNoSuchFile {
            return []
        }
    }

    public func save(_ events: [POSCashEvent]) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(events).write(to: fileURL, options: .atomic)
    }
}
