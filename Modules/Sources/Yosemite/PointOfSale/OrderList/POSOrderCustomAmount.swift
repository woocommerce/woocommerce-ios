import Foundation

public struct POSOrderCustomAmount: Equatable, Hashable, Identifiable {
    public let id: Int64
    public let name: String
    public let formattedTotal: String
    public let total: Decimal
    public let totalTax: Decimal

    public init(id: Int64,
                name: String,
                formattedTotal: String,
                total: Decimal = 0,
                totalTax: Decimal = 0) {
        self.id = id
        self.name = name
        self.formattedTotal = formattedTotal
        self.total = total
        self.totalTax = totalTax
    }
}
