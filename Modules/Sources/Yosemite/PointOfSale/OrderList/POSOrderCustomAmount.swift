import Foundation

public struct POSOrderCustomAmount: Equatable, Hashable, Identifiable {
    public let id: Int64
    public let name: String
    public let formattedTotal: String

    public init(id: Int64, name: String, formattedTotal: String) {
        self.id = id
        self.name = name
        self.formattedTotal = formattedTotal
    }
}
