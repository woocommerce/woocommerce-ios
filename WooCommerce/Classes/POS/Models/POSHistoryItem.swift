import Foundation

public struct HistoryItem: Identifiable {
    public let createdAt: Date
    public let id: UUID = UUID()
    // TODO: add data like products, amount, is it a purchase or a refund etc.
}
