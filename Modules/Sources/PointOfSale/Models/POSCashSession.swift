import Foundation

/// Session data used by the cash drawer UI. A real service can map its API response to this model.
public struct POSCashSession: Identifiable, Equatable {
    public let id: Int64
    public let currency: String?
    public let currencyPrecision: Int?
    public let openedAt: Date
    public let openedBy: String
    public let openingCash: Decimal
    public var movements: [POSCashSessionMovement]
    public var closedAt: Date? = nil
    public var closedBy: String? = nil
    public var countedCash: Decimal? = nil
    public var closingNote: String? = nil
    public var revision: Int = 0
    /// Server totals are authoritative when the API has not loaded every movement page.
    public var totals: POSCashSessionTotals? = nil

    public init(id: Int64, openedAt: Date, openedBy: String, openingCash: Decimal,
                movements: [POSCashSessionMovement], closedAt: Date? = nil, closedBy: String? = nil,
                countedCash: Decimal? = nil, closingNote: String? = nil, revision: Int = 0,
                totals: POSCashSessionTotals? = nil, currency: String? = nil, currencyPrecision: Int? = nil) {
        self.id = id
        self.currency = currency
        self.currencyPrecision = currencyPrecision
        self.openedAt = openedAt
        self.openedBy = openedBy
        self.openingCash = openingCash
        self.movements = movements
        self.closedAt = closedAt
        self.closedBy = closedBy
        self.countedCash = countedCash
        self.closingNote = closingNote
        self.revision = revision
        self.totals = totals
    }

    public var cashSales: Decimal { totals?.cashSales ?? total(for: .cashSale) }
    public var cashRefunds: Decimal { totals?.cashRefunds ?? total(for: .cashRefund) }
    public var paidInOut: Decimal { totals.map { $0.paidIn - $0.paidOut } ?? (total(for: .payIn) - total(for: .payOut)) }
    public var expectedCash: Decimal { totals?.expectedCash ?? (openingCash + cashSales + paidInOut - cashRefunds) }
    public var difference: Decimal? { countedCash.map { $0 - expectedCash } }

    private func total(for kind: POSCashSessionMovement.Kind) -> Decimal {
        movements.filter { $0.kind == kind }.reduce(Decimal.zero) { $0 + $1.amount }
    }
}

public struct POSCashSessionTotals: Equatable {
    public let cashSales: Decimal
    public let cashRefunds: Decimal
    public let paidIn: Decimal
    public let paidOut: Decimal
    public let expectedCash: Decimal

    public init(cashSales: Decimal, cashRefunds: Decimal, paidIn: Decimal, paidOut: Decimal, expectedCash: Decimal) {
        self.cashSales = cashSales
        self.cashRefunds = cashRefunds
        self.paidIn = paidIn
        self.paidOut = paidOut
        self.expectedCash = expectedCash
    }
}

public struct POSCashSessionMovement: Identifiable, Equatable {
    public enum Kind: Equatable {
        case cashSale
        case cashRefund
        case payIn
        case payOut
    }

    public let id: UUID
    public let kind: Kind
    public let amount: Decimal
    public let date: Date
    public let actor: String
    public let orderID: Int64?
    public let note: String?

    public init(id: UUID, kind: Kind, amount: Decimal, date: Date, actor: String,
                orderID: Int64?, note: String?) {
        self.id = id
        self.kind = kind
        self.amount = amount
        self.date = date
        self.actor = actor
        self.orderID = orderID
        self.note = note
    }

    public var signedAmount: Decimal {
        switch kind {
        case .cashSale, .payIn: amount
        case .cashRefund, .payOut: -amount
        }
    }
}
