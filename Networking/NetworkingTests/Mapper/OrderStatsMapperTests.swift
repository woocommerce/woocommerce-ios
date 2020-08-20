import XCTest
@testable import Networking


/// OrderStatsMapper Unit Tests
///
class OrderStatsMapperTests: XCTestCase {

    /// Verifies that all of the day unit OrderStats fields are parsed correctly.
    ///
    func test_day_unit_stat_fields_are_properly_parsed() {
        guard let dayStats = mapOrderStatsWithDayUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(dayStats.granularity, .day)
        XCTAssertEqual(dayStats.date, "2018-06-08")
        XCTAssertEqual(dayStats.quantity, "31")
        XCTAssertEqual(dayStats.totalOrders, 9)
        XCTAssertEqual(dayStats.totalProducts, 13)
        XCTAssertEqual(dayStats.totalGrossSales, 439.23)
        XCTAssertEqual(dayStats.totalNetSales, 438.24)
        XCTAssertEqual(dayStats.averageGrossSales, 14.1687)
        XCTAssertEqual(dayStats.averageNetSales, 14.1368)
        XCTAssertEqual(dayStats.averageOrders, 0.2903)
        XCTAssertEqual(dayStats.averageProducts, 0.4194)
        XCTAssertEqual(dayStats.items!.count, 31)

        let sampleItem1 = dayStats.items![0]
        XCTAssertEqual(sampleItem1.period, "2018-05-09")
        XCTAssertEqual(sampleItem1.orders, 0)
        XCTAssertEqual(sampleItem1.products, 0)
        XCTAssertEqual(sampleItem1.coupons, 0)
        XCTAssertEqual(sampleItem1.couponDiscount, 0)
        XCTAssertEqual(sampleItem1.totalSales, 0)
        XCTAssertEqual(sampleItem1.totalTax, 0)
        XCTAssertEqual(sampleItem1.totalShipping, 0)
        XCTAssertEqual(sampleItem1.totalShippingTax, 0)
        XCTAssertEqual(sampleItem1.totalRefund, 0)
        XCTAssertEqual(sampleItem1.totalTaxRefund, 0)
        XCTAssertEqual(sampleItem1.totalShippingRefund, 0)
        XCTAssertEqual(sampleItem1.totalShippingTaxRefund, 0)
        XCTAssertEqual(sampleItem1.currency, "USD")
        XCTAssertEqual(sampleItem1.grossSales, 0)
        XCTAssertEqual(sampleItem1.netSales, 0)
        XCTAssertEqual(sampleItem1.avgOrderValue, 0)
        XCTAssertEqual(sampleItem1.avgProductsPerOrder, 0)

        let sampleItem2 = dayStats.items![23]
        XCTAssertEqual(sampleItem2.period, "2018-06-01")
        XCTAssertEqual(sampleItem2.orders, 2)
        XCTAssertEqual(sampleItem2.products, 2)
        XCTAssertEqual(sampleItem2.coupons, 0)
        XCTAssertEqual(sampleItem2.couponDiscount, 0)
        XCTAssertEqual(sampleItem2.totalSales, 14.24)
        XCTAssertEqual(sampleItem2.totalTax, 0.12)
        XCTAssertEqual(sampleItem2.totalShipping, 9.98)
        XCTAssertEqual(sampleItem2.totalShippingTax, 0.28)
        XCTAssertEqual(sampleItem2.totalRefund, 0)
        XCTAssertEqual(sampleItem2.totalTaxRefund, 0)
        XCTAssertEqual(sampleItem2.totalShippingRefund, 0)
        XCTAssertEqual(sampleItem2.totalShippingTaxRefund, 0)
        XCTAssertEqual(sampleItem2.currency, "USD")
        XCTAssertEqual(sampleItem2.grossSales, 14.24)
        XCTAssertEqual(sampleItem2.netSales, 14.120000000000001)
        XCTAssertEqual(sampleItem2.avgOrderValue, 7.12)
        XCTAssertEqual(sampleItem2.avgProductsPerOrder, 1)
    }

    /// Verifies that all of the week unit OrderStats fields are parsed correctly.
    ///
    func test_week_unit_stat_fields_are_properly_parsed() {
        guard let weekStats = mapOrderStatsWithWeekUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(weekStats.granularity, .week)
        XCTAssertEqual(weekStats.date, "2018-W30")
        XCTAssertEqual(weekStats.quantity, "31")
        XCTAssertEqual(weekStats.totalOrders, 65)
        XCTAssertEqual(weekStats.totalProducts, 87)
        XCTAssertEqual(weekStats.totalGrossSales, 2858.52)
        XCTAssertEqual(weekStats.totalNetSales, 2833.5499999999997)
        XCTAssertEqual(weekStats.averageGrossSales, 92.2103)
        XCTAssertEqual(weekStats.averageNetSales, 91.4048)
        XCTAssertEqual(weekStats.averageOrders, 2.0968)
        XCTAssertEqual(weekStats.averageProducts, 2.8065)
        XCTAssertEqual(weekStats.items!.count, 31)

        let sampleItem1 = weekStats.items![0]
        XCTAssertEqual(sampleItem1.period, "2017-W52")
        XCTAssertEqual(sampleItem1.orders, 0)
        XCTAssertEqual(sampleItem1.products, 0)
        XCTAssertEqual(sampleItem1.coupons, 0)
        XCTAssertEqual(sampleItem1.couponDiscount, 0)
        XCTAssertEqual(sampleItem1.totalSales, 0)
        XCTAssertEqual(sampleItem1.totalTax, 0)
        XCTAssertEqual(sampleItem1.totalShipping, 0)
        XCTAssertEqual(sampleItem1.totalShippingTax, 0)
        XCTAssertEqual(sampleItem1.totalRefund, 0)
        XCTAssertEqual(sampleItem1.totalTaxRefund, 0)
        XCTAssertEqual(sampleItem1.totalShippingRefund, 0)
        XCTAssertEqual(sampleItem1.totalShippingTaxRefund, 0)
        XCTAssertEqual(sampleItem1.currency, "USD")
        XCTAssertEqual(sampleItem1.grossSales, 0)
        XCTAssertEqual(sampleItem1.netSales, 0)
        XCTAssertEqual(sampleItem1.avgOrderValue, 0)
        XCTAssertEqual(sampleItem1.avgProductsPerOrder, 0)

        let sampleItem2 = weekStats.items![1]
        XCTAssertEqual(sampleItem2.period, "2018-W01")
        XCTAssertEqual(sampleItem2.orders, 2)
        XCTAssertEqual(sampleItem2.products, 4)
        XCTAssertEqual(sampleItem2.coupons, 0)
        XCTAssertEqual(sampleItem2.couponDiscount, 0)
        XCTAssertEqual(sampleItem2.totalSales, 160)
        XCTAssertEqual(sampleItem2.totalTax, 0)
        XCTAssertEqual(sampleItem2.totalShipping, 0)
        XCTAssertEqual(sampleItem2.totalShippingTax, 0)
        XCTAssertEqual(sampleItem2.totalRefund, 0)
        XCTAssertEqual(sampleItem2.totalTaxRefund, 0)
        XCTAssertEqual(sampleItem2.totalShippingRefund, 0)
        XCTAssertEqual(sampleItem2.totalShippingTaxRefund, 0)
        XCTAssertEqual(sampleItem2.currency, "USD")
        XCTAssertEqual(sampleItem2.grossSales, 160)
        XCTAssertEqual(sampleItem2.netSales, 160)
        XCTAssertEqual(sampleItem2.avgOrderValue, 80)
        XCTAssertEqual(sampleItem2.avgProductsPerOrder, 2)

        let sampleItem3 = weekStats.items![2]
        XCTAssertEqual(sampleItem3.period, "2018-W02")
        XCTAssertEqual(sampleItem3.orders, 0)
        XCTAssertEqual(sampleItem3.products, 0)
        XCTAssertEqual(sampleItem3.coupons, 0)
        XCTAssertEqual(sampleItem3.couponDiscount, 0)
        XCTAssertEqual(sampleItem3.totalSales, 0)
        XCTAssertEqual(sampleItem3.totalTax, 0)
        XCTAssertEqual(sampleItem3.totalShipping, 0)
        XCTAssertEqual(sampleItem3.totalShippingTax, 0)
        XCTAssertEqual(sampleItem3.totalRefund, 160)
        XCTAssertEqual(sampleItem3.totalTaxRefund, 0)
        XCTAssertEqual(sampleItem3.totalShippingRefund, 0)
        XCTAssertEqual(sampleItem3.totalShippingTaxRefund, 0)
        XCTAssertEqual(sampleItem3.currency, "USD")
        XCTAssertEqual(sampleItem3.grossSales, -160)
        XCTAssertEqual(sampleItem3.netSales, -160)
        XCTAssertEqual(sampleItem3.avgOrderValue, 0)
        XCTAssertEqual(sampleItem3.avgProductsPerOrder, 0)
    }

    /// Verifies that all of the month unit OrderStats fields are parsed correctly.
    ///
    func test_month_unit_stat_fields_are_properly_parsed() {
        guard let monthStats = mapOrderStatsWithMonthUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(monthStats.granularity, .month)
        XCTAssertEqual(monthStats.date, "2018-06")
        XCTAssertEqual(monthStats.quantity, "12")
        XCTAssertEqual(monthStats.totalOrders, 159)
        XCTAssertEqual(monthStats.totalProducts, 243)
        XCTAssertEqual(monthStats.totalGrossSales, 6830.590000000002)
        XCTAssertEqual(monthStats.totalNetSales, 6717.232000000002)
        XCTAssertEqual(monthStats.averageGrossSales, 569.2158)
        XCTAssertEqual(monthStats.averageNetSales, 559.7693)
        XCTAssertEqual(monthStats.averageOrders, 13.25)
        XCTAssertEqual(monthStats.averageProducts, 20.25)
        XCTAssertEqual(monthStats.items!.count, 12)

        let sampleItem1 = monthStats.items![0]
        XCTAssertEqual(sampleItem1.period, "2017-07")
        XCTAssertEqual(sampleItem1.orders, 49)
        XCTAssertEqual(sampleItem1.products, 74)
        XCTAssertEqual(sampleItem1.coupons, 1)
        XCTAssertEqual(sampleItem1.couponDiscount, 7.5)
        XCTAssertEqual(sampleItem1.totalSales, 1602.2500000000014)
        XCTAssertEqual(sampleItem1.totalTax, 50.78999999999998)
        XCTAssertEqual(sampleItem1.totalShipping, 117.31)
        XCTAssertEqual(sampleItem1.totalShippingTax, 4.200800000000001)
        XCTAssertEqual(sampleItem1.totalRefund, 0)
        XCTAssertEqual(sampleItem1.totalTaxRefund, 0)
        XCTAssertEqual(sampleItem1.totalShippingRefund, 0)
        XCTAssertEqual(sampleItem1.totalShippingTaxRefund, 0)
        XCTAssertEqual(sampleItem1.currency, "USD")
        XCTAssertEqual(sampleItem1.grossSales, 1602.2500000000014)
        XCTAssertEqual(sampleItem1.netSales, 1551.4600000000014)
        XCTAssertEqual(sampleItem1.avgOrderValue, 32.699)
        XCTAssertEqual(sampleItem1.avgProductsPerOrder, 1.5102)

        let sampleItem2 = monthStats.items![11]
        XCTAssertEqual(sampleItem2.period, "2018-06")
        XCTAssertEqual(sampleItem2.orders, 10)
        XCTAssertEqual(sampleItem2.products, 12)
        XCTAssertEqual(sampleItem2.coupons, 0)
        XCTAssertEqual(sampleItem2.couponDiscount, 0)
        XCTAssertEqual(sampleItem2.totalSales, 511.58000000000004)
        XCTAssertEqual(sampleItem2.totalTax, 1.28)
        XCTAssertEqual(sampleItem2.totalShipping, 96.16000000000001)
        XCTAssertEqual(sampleItem2.totalShippingTax, 0.28)
        XCTAssertEqual(sampleItem2.totalRefund, 2.06)
        XCTAssertEqual(sampleItem2.totalTaxRefund, 0.06)
        XCTAssertEqual(sampleItem2.totalShippingRefund, 0)
        XCTAssertEqual(sampleItem2.totalShippingTaxRefund, 0)
        XCTAssertEqual(sampleItem2.currency, "USD")
        XCTAssertEqual(sampleItem2.grossSales, 509.52000000000004)
        XCTAssertEqual(sampleItem2.netSales, 508.24000000000007)
        XCTAssertEqual(sampleItem2.avgOrderValue, 50.952)
        XCTAssertEqual(sampleItem2.avgProductsPerOrder, 1.2)
    }

    /// Verifies that all of the year unit OrderStats fields are parsed correctly.
    ///
    func test_year_unit_stat_fields_are_properly_parsed() {
        guard let yearStats = mapOrderStatsWithYearUnitResponse() else {
            XCTFail()
            return
        }

        XCTAssertEqual(yearStats.granularity, .year)
        XCTAssertEqual(yearStats.date, "2018")
        XCTAssertEqual(yearStats.quantity, "4")
        XCTAssertEqual(yearStats.totalOrders, 293)
        XCTAssertEqual(yearStats.totalProducts, 626)
        XCTAssertEqual(yearStats.totalGrossSales, 10928.91999999999)
        XCTAssertEqual(yearStats.totalNetSales, 10684.27199999999)
        XCTAssertEqual(yearStats.averageGrossSales, 2732.23)
        XCTAssertEqual(yearStats.averageNetSales, 2671.068)
        XCTAssertEqual(yearStats.averageOrders, 73.25)
        XCTAssertEqual(yearStats.averageProducts, 156.5)
        XCTAssertEqual(yearStats.items!.count, 4)

        let sampleItem1 = yearStats.items![2]
        XCTAssertEqual(sampleItem1.period, "2017")
        XCTAssertEqual(sampleItem1.orders, 228)
        XCTAssertEqual(sampleItem1.products, 539)
        XCTAssertEqual(sampleItem1.coupons, 32)
        XCTAssertEqual(sampleItem1.couponDiscount, 237.14000000000007)
        XCTAssertEqual(sampleItem1.totalSales, 9813.699999999988)
        XCTAssertEqual(sampleItem1.totalTax, 219.6780000000001)
        XCTAssertEqual(sampleItem1.totalShipping, 1466.0300000000007)
        XCTAssertEqual(sampleItem1.totalShippingTax, 27.6736)
        XCTAssertEqual(sampleItem1.totalRefund, 1743.3)
        XCTAssertEqual(sampleItem1.totalTaxRefund, 12.47)
        XCTAssertEqual(sampleItem1.totalShippingRefund, 202.83)
        XCTAssertEqual(sampleItem1.totalShippingTaxRefund, 4.386)
        XCTAssertEqual(sampleItem1.currency, "USD")
        XCTAssertEqual(sampleItem1.grossSales, 8070.399999999988)
        XCTAssertEqual(sampleItem1.netSales, 7850.721999999988)
        XCTAssertEqual(sampleItem1.avgOrderValue, 35.3965)
        XCTAssertEqual(sampleItem1.avgProductsPerOrder, 2.364)

        let sampleItem2 = yearStats.items![3]
        XCTAssertEqual(sampleItem2.period, "2018")
        XCTAssertEqual(sampleItem2.orders, 65)
        XCTAssertEqual(sampleItem2.products, 87)
        XCTAssertEqual(sampleItem2.coupons, 4)
        XCTAssertEqual(sampleItem2.couponDiscount, 140)
        XCTAssertEqual(sampleItem2.totalSales, 3176.580000000001)
        XCTAssertEqual(sampleItem2.totalTax, 24.97)
        XCTAssertEqual(sampleItem2.totalShipping, 517.95)
        XCTAssertEqual(sampleItem2.totalShippingTax, 17.3)
        XCTAssertEqual(sampleItem2.totalRefund, 318.06)
        XCTAssertEqual(sampleItem2.totalTaxRefund, 0.06)
        XCTAssertEqual(sampleItem2.totalShippingRefund, 11)
        XCTAssertEqual(sampleItem2.totalShippingTaxRefund, 0)
        XCTAssertEqual(sampleItem2.currency, "USD")
        XCTAssertEqual(sampleItem2.grossSales, 2858.520000000001)
        XCTAssertEqual(sampleItem2.netSales, 2833.550000000001)
        XCTAssertEqual(sampleItem2.avgOrderValue, 43.9772)
        XCTAssertEqual(sampleItem2.avgProductsPerOrder, 1.3385)
    }
}


/// Private Methods.
///
private extension OrderStatsMapperTests {

    /// Returns the OrderNotesMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapStatItems(from filename: String) -> OrderStats? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! OrderStatsMapper().map(response: response)
    }

    /// Returns the OrderStatsMapper output upon receiving `order-stats-day`
    ///
    func mapOrderStatsWithDayUnitResponse() -> OrderStats? {
        return mapStatItems(from: "order-stats-day")
    }

    /// Returns the OrderStatsMapper output upon receiving `order-stats-week`
    ///
    func mapOrderStatsWithWeekUnitResponse() -> OrderStats? {
        return mapStatItems(from: "order-stats-week")
    }

    /// Returns the OrderStatsMapper output upon receiving `order-stats-month`
    ///
    func mapOrderStatsWithMonthUnitResponse() -> OrderStats? {
        return mapStatItems(from: "order-stats-month")
    }

    /// Returns the OrderStatsMapper output upon receiving `order-stats-year`
    ///
    func mapOrderStatsWithYearUnitResponse() -> OrderStats? {
        return mapStatItems(from: "order-stats-year")
    }
}
