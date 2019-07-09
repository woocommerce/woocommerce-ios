import Foundation

public struct OrderStatsTotals: Decodable {
    public let orders: Int
    public let itemsSold: Int
    public let grossRevenue: Double
    public let couponDiscount: Double
    public let coupons: Int
    public let refunds: Double
    public let taxes: Double
    public let shipping: Double
    public let netRevenue: Double
    public let products: Int

    public init(orders: Int,
                itemsSold: Int,
                grossRevenue: Double,
                couponDiscount: Double,
                coupons: Int,
                refunds: Double,
                taxes: Double,
                shipping: Double,
                netRevenue: Double,
                products: Int) {
        self.orders = orders
        self.itemsSold = itemsSold
        self.grossRevenue = grossRevenue
        self.couponDiscount = couponDiscount
        self.coupons = coupons
        self.refunds = refunds
        self.taxes = taxes
        self.shipping = shipping
        self.netRevenue = netRevenue
        self.products = products
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let orders = try container.decode(Int.self, forKey: .ordersCount)
        let itemsSold = try container.decode(Int.self, forKey: .itemsSold)
        let grossRevenue = try container.decode(Double.self, forKey: .grossRevenue)
        let couponDiscount = try container.decode(Double.self, forKey: .couponDiscount)
        let coupons = try container.decode(Int.self, forKey: .coupons)
        let refunds = try container.decode(Double.self, forKey: .refunds)
        let taxes = try container.decode(Double.self, forKey: .taxes)
        let shipping = try container.decode(Double.self, forKey: .shipping)
        let netRevenue = try container.decode(Double.self, forKey: .netRevenue)
        let products = try container.decode(Int.self, forKey: .products)

        self.init(orders: orders,
                  itemsSold: itemsSold,
                  grossRevenue: grossRevenue,
                  couponDiscount: couponDiscount,
                  coupons: coupons,
                  refunds: refunds,
                  taxes: taxes,
                  shipping: shipping,
                  netRevenue: netRevenue,
                  products: products)
    }
}

private extension OrderStatsTotals {
    enum CodingKeys: String, CodingKey {
        case ordersCount = "orders_count"
        case itemsSold = "num_items_sold"
        case grossRevenue = "gross_revenue"
        case couponDiscount = "coupons"
        case coupons = "coupons_count"
        case refunds = "refunds"
        case taxes = "taxes"
        case shipping = "shipping"
        case netRevenue = "net_revenue"
        case products = "products"
    }
}


extension OrderStatsTotals: Equatable {
    public static func == (lhs: OrderStatsTotals, rhs: OrderStatsTotals) -> Bool {
        return lhs.orders == rhs.orders &&
            lhs.itemsSold == rhs.itemsSold &&
            lhs.grossRevenue == rhs.grossRevenue &&
            lhs.couponDiscount == rhs.couponDiscount &&
            lhs.coupons == rhs.coupons &&
            lhs.refunds == rhs.refunds &&
            lhs.taxes == rhs.taxes &&
            lhs.shipping == rhs.shipping &&
            lhs.netRevenue == rhs.netRevenue &&
            lhs.products == rhs.products
    }

    public static func < (lhs: OrderStatsTotals, rhs: OrderStatsTotals) -> Bool {
        return lhs.grossRevenue < rhs.grossRevenue ||
            (lhs.grossRevenue == rhs.grossRevenue && lhs.orders < rhs.orders)
    }
}

/// Represents an single order stat for a specific period.
/// v4 API
public struct OrderStatsInterval: Decodable {
    public let interval: String
    public let dateStart: String
    public let dateEnd: String
    public let subtotals: OrderStatsTotals

    public init(interval: String,
                dateStart: String,
                dateEnd: String,
                subtotals: OrderStatsTotals) {
        self.interval = interval
        self.dateStart = dateStart
        self.dateEnd = dateEnd
        self.subtotals = subtotals
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let interval = try container.decode(String.self, forKey: .interval)
        let dateStart = try container.decode(String.self, forKey: .dateStart)
        let dateEnd = try container.decode(String.self, forKey: .dateEnd)
        let subtotals = try container.decode(OrderStatsTotals.self, forKey: .subtotals)

        self.init(interval: interval,
                  dateStart: dateStart,
                  dateEnd: dateEnd,
                  subtotals: subtotals)
    }
}

extension OrderStatsInterval: Comparable {
    public static func == (lhs: OrderStatsInterval, rhs: OrderStatsInterval) -> Bool {
        return lhs.interval == rhs.interval &&
            lhs.dateStart == rhs.dateStart &&
            lhs.dateEnd == rhs.dateEnd &&
            lhs.subtotals == rhs.subtotals
    }

    public static func < (lhs: OrderStatsInterval, rhs: OrderStatsInterval) -> Bool {
        return lhs.interval < rhs.interval ||
            (lhs.interval == rhs.interval && lhs.subtotals < rhs.subtotals)
    }
}

private extension OrderStatsInterval {
    enum CodingKeys: String, CodingKey {
        case interval = "interval"
        case dateStart = "date_start"
        case dateEnd = "date_end"
        case subtotals = "subtotals"
    }
}


public struct OrderStatsV4: Decodable {
    public let totals: OrderStatsTotals
    public let intervals: [OrderStatsInterval]

    public init(totals: OrderStatsTotals,
                intervals: [OrderStatsInterval]) {
        self.totals = totals
        self.intervals = intervals
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let totals = try container.decode(OrderStatsTotals.self, forKey: .totals)
        let intervals = try container.decode([OrderStatsInterval].self, forKey: .intervals)

        self.init(totals: totals, intervals: intervals)
    }
}


// MARK: - Constants!
//

private extension OrderStatsV4 {

    enum CodingKeys: String, CodingKey {
        case totals = "totals"
        case intervals = "intervals"
    }
}

