import Foundation
import SwiftUI
import UIKit
import Yosemite
import WooAIAssistant
import WooFoundation

@MainActor
struct AIAssistantExternalViewsAdaptor: AssistantExternalViewProviding {

    private let currencySettings: CurrencySettings

    init(currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.currencySettings = currencySettings
    }

    // MARK: - AssistantExternalViewProviding

    @MainActor func orderRow(payload: OrderCardPayload,
                             showDivider: Bool,
                             onTap: @escaping @MainActor () -> Void) -> AnyView? {
        let data = makeOrderRowData(from: payload)
        return AnyView(
            LastOrderDashboardRow(data: data, showDivider: showDivider, paddedRow: true, tapHandler: { onTap() })
        )
    }

    @MainActor func productRow(payload: ProductCardPayload,
                               showDivider: Bool,
                               onTap: @escaping @MainActor () -> Void) -> AnyView? {
        let data = ProductStockRow.RowData(
            imageURL: payload.firstImageURL,
            name: payload.name ?? "",
            subtitle: productDetails(for: payload),
            accessoryText: productAccessoryText(for: payload)
        )
        return AnyView(ProductStockRow(data: data,
                                       showDivider: showDivider,
                                       paddedRow: true,
                                       tapHandler: { onTap() }))
    }

    @MainActor func productVariationRow(payload: ProductVariationCardPayload,
                                        showDivider: Bool,
                                        onTap: @escaping @MainActor () -> Void) -> AnyView? {
        let displayName: String
        if let name = payload.name, !name.isEmpty {
            displayName = name
        } else {
            displayName = skuOrIDLabel(for: payload)
        }
        let data = ProductStockRow.RowData(
            imageURL: payload.firstImageURL,
            name: displayName,
            subtitle: variationDetails(for: payload),
            accessoryText: variationAccessoryText(for: payload)
        )
        return AnyView(ProductStockRow(data: data,
                                       showDivider: showDivider,
                                       paddedRow: true,
                                       tapHandler: { onTap() }))
    }

    @MainActor func customerRow(payload: CustomerCardPayload,
                                showDivider: Bool,
                                onTap: @escaping @MainActor () -> Void) -> AnyView? {
        guard let name = payload.displayName else { return nil }
        let ordersCountDetail: String? = payload.ordersCount.map { count in
            count == 1 ? Localization.singleOrder : String(format: Localization.orderCount, NSNumber(value: count))
        }
        return AnyView(
            VStack(spacing: 0) {
                Button(action: { onTap() }) {
                    TitleAndSubtitleAndDetailRow(
                        title: name,
                        detail: ordersCountDetail,
                        subtitle: payload.email,
                        subtitlePlaceholder: Localization.customerNoEmail
                    )
                    .padding(.horizontal, Layout.rowHorizontalPadding)
                    .padding(.vertical, Layout.rowVerticalPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(AssistantPressableButtonStyle())
                if showDivider {
                    Divider().padding(.leading, Layout.rowHorizontalPadding)
                }
            }
        )
    }

    @MainActor func statsCardView(toolName: String, payload: AnyCodableJSON) -> AnyView? {
        guard let mapping = StatsCardMapping(toolName: toolName) else { return nil }
        let totals = payload.assistantObject("totals")
        let intervals = payload.assistantArray("interval_subtotals") ?? []
        let currency = totals?.assistantString("currency") ?? payload.assistantString("currency")

        let topRow = makeAnalyticsRow(mapping: mapping.topRow,
                                      totals: totals,
                                      intervals: intervals,
                                      currency: currency)
        let bottomRow = makeAnalyticsRow(mapping: mapping.bottomRow,
                                         totals: totals,
                                         intervals: intervals,
                                         currency: currency)
        guard topRow != nil || bottomRow != nil else { return nil }

        let subtitle = formatDateRange(after: payload.assistantString("after"),
                                       before: payload.assistantString("before"))
        return AnyView(
            AssistantDashboardCardShell(title: Localization.analyticsTitle,
                                        iconSystemName: "chart.bar",
                                        subtitle: subtitle,
                                        padBody: false) {
                VStack(spacing: 0) {
                    if let topRow {
                        topRow
                    }
                    if topRow != nil && bottomRow != nil {
                        Divider().padding(.horizontal, 16)
                    }
                    if let bottomRow {
                        bottomRow
                    }
                }
            }
        )
    }

    @MainActor private func makeAnalyticsRow(mapping: StatsRowMapping,
                                             totals: AnyCodableJSON?,
                                             intervals: [AnyCodableJSON],
                                             currency: String?) -> AnyView? {
        let leadingValue = formatMetric(mapping.leading, totals: totals, currency: currency)
        let trailingValue = formatMetric(mapping.trailing, totals: totals, currency: currency)
        let bothMissing = leadingValue == Localization.metricUnavailable
            && trailingValue == Localization.metricUnavailable
        guard !bothMissing else { return nil }

        let leadingChartData = chartData(for: mapping.leading, intervals: intervals)
        let trailingChartData = chartData(for: mapping.trailing, intervals: intervals)
        return AnyView(
            AnalyticsReportCard(
                title: "",
                leadingTitle: mapping.leadingTitle,
                leadingValue: leadingValue,
                leadingDelta: nil,
                leadingDeltaColor: nil,
                leadingDeltaTextColor: nil,
                leadingChartData: leadingChartData,
                leadingChartColor: leadingChartData.isEmpty ? nil : .accent,
                trailingTitle: mapping.trailingTitle,
                trailingValue: trailingValue,
                trailingDelta: nil,
                trailingDeltaColor: nil,
                trailingDeltaTextColor: nil,
                trailingChartData: trailingChartData,
                trailingChartColor: trailingChartData.isEmpty ? nil : .accent,
                reportViewModel: nil,
                isRedacted: false,
                showSyncError: false,
                syncErrorMessage: ""
            )
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        )
    }

    // MARK: - Order rows

    private func makeOrderRowData(from payload: OrderCardPayload) -> LastOrderDashboardRow.RowData {
        let statusEnum = OrderStatusEnum(rawValue: payload.status ?? "")
        let formatter = CurrencyFormatter(currencySettings: currencySettings)
        let total = formatter.formatAmount(payload.total ?? "", with: payload.currency) ?? ""
        return LastOrderDashboardRow.RowData(
            number: orderNumberLabel(for: payload),
            date: formattedDate(for: payload.dateCreated),
            customerName: customerNameLabel(for: payload),
            total: total,
            statusDescription: statusEnum.description,
            statusBackgroundColor: Color(uiColor: statusEnum.backgroundColor),
            fulfillmentBadgeText: nil,
            fulfillmentBadgeBackgroundColor: nil,
            salesChannelText: nil
        )
    }

    private func orderNumberLabel(for payload: OrderCardPayload) -> String {
        if let number = payload.number, !number.isEmpty {
            return "#\(number)"
        }
        if let id = payload.id {
            return "#\(id)"
        }
        return ""
    }

    private func customerNameLabel(for payload: OrderCardPayload) -> String {
        if let name = payload.customerName, !name.isEmpty {
            return name
        }
        // No billing name on file. customer_id > 0 means a registered customer;
        // surface their email or id rather than the misleading "Guest" label.
        if let id = payload.customerID, id > 0 {
            if let email = payload.customerEmail, !email.isEmpty {
                return email
            }
            return String(format: Localization.registeredCustomerWithID, "\(id)")
        }
        return Localization.guestCustomer
    }

    private func formattedDate(for raw: String?) -> String {
        guard let raw, let date = parseDate(raw) else { return "" }
        let isSameYear = date.isSameYear(as: Date())
        let formatter: DateFormatter = isSameYear ? .monthAndDayFormatter : .mediumLengthLocalizedDateFormatter
        formatter.timeZone = .siteTimezone
        return formatter.string(from: date)
    }

    private func parseDate(_ raw: String) -> Date? {
        if let date = ISO8601DateFormatter.assistantWithFraction.date(from: raw) { return date }
        if let date = ISO8601DateFormatter.assistantNoFraction.date(from: raw) { return date }
        return DateFormatter.assistantWCLocalFallback.date(from: raw)
    }

    // MARK: - Product rows

    // Mirrors the Products tab: subtitle = stock detail, accessory = formatted price.
    // Variable products append a "· N variations" segment so the merchant sees variation count
    // without having to drill in.
    func productDetails(for payload: ProductCardPayload) -> String {
        let stockOrSKU = productStockDetail(stockStatus: payload.stockStatus, stockQuantity: payload.stockQuantity)
            ?? payload.sku.flatMap { $0.isEmpty ? nil : "SKU: \($0)" }
        return joinWithMiddleDot(stockOrSKU, variationsLabel(count: payload.variationsCount))
    }

    private func variationsLabel(count: Int?) -> String? {
        guard let count, count > 0 else { return nil }
        if count == 1 { return Localization.singleVariation }
        let formatted = NumberFormatter.localizedString(from: NSNumber(value: count), number: .none)
        return String(format: Localization.variationsCount, formatted)
    }

    private func joinWithMiddleDot(_ first: String?, _ second: String?) -> String {
        [first, second].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " \u{00B7} ")
    }

    private func variationDetails(for payload: ProductVariationCardPayload) -> String {
        productStockDetail(stockStatus: payload.stockStatus, stockQuantity: payload.stockQuantity)
            ?? payload.sku.flatMap { $0.isEmpty ? nil : "SKU: \($0)" }
            ?? ""
    }

    // Inline count when known so "low stock" queries see the number; otherwise show the status badge.
    private func productStockDetail(stockStatus: String?, stockQuantity: Double?) -> String? {
        guard let badge = stockBadgeText(for: stockStatus) else { return nil }
        guard let quantity = stockQuantity else { return badge }
        if quantity <= 0 { return Localization.outOfStock }
        return String(format: Localization.stockCountFormat, formattedStockAccessory(quantity: quantity))
    }

    private func skuOrIDLabel(for payload: ProductVariationCardPayload) -> String {
        if let sku = payload.sku, !sku.isEmpty { return sku }
        if let id = payload.id { return "#\(id)" }
        return ""
    }

    private func formattedPrice(raw: String?, currency: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        return CurrencyFormatter(currencySettings: currencySettings).formatAmount(raw, with: currency)
    }

    private func stockBadgeText(for slug: String?) -> String? {
        guard let slug, !slug.isEmpty else { return nil }
        switch slug.lowercased() {
        case "instock":
            return Localization.inStock
        case "outofstock":
            return Localization.outOfStock
        case "onbackorder":
            return Localization.onBackorder
        default:
            return slug.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    func productAccessoryText(for payload: ProductCardPayload) -> String {
        formattedPrice(raw: payload.price ?? payload.regularPrice, currency: nil) ?? ""
    }

    func variationAccessoryText(for payload: ProductVariationCardPayload) -> String {
        formattedPrice(raw: payload.price ?? payload.regularPrice, currency: nil) ?? ""
    }

    private func formattedStockAccessory(quantity: Double) -> String {
        if quantity <= 0 { return Localization.outOfStock }
        let rounded = Int(quantity)
        if Double(rounded) == quantity {
            let count = NumberFormatter.localizedString(from: NSNumber(value: rounded), number: .none)
            return String(format: Localization.stockLeft, count)
        }
        let count = NumberFormatter.localizedString(from: NSNumber(value: quantity), number: .decimal)
        return String(format: Localization.stockLeft, count)
    }

    // MARK: - Analytics card

    private func formatMetric(_ metric: StatsMetric,
                              totals: AnyCodableJSON?,
                              currency: String?) -> String {
        switch metric.kind {
        case .currency:
            let formatter = CurrencyFormatter(currencySettings: currencySettings)
            for key in metric.keys {
                guard let raw = totals?.assistantString(key) else { continue }
                if let formatted = formatter.formatAmount(raw, with: currency) {
                    return formatted
                }
            }
        case .integer:
            for key in metric.keys {
                if let value = totals?.assistantInt(key) {
                    return NumberFormatter.localizedString(from: NSNumber(value: value), number: .none)
                }
            }
        }
        return Localization.metricUnavailable
    }

    func testChartData(forKeys keys: [String], payload: AnyCodableJSON) -> [Double] {
        let intervals = payload.assistantArray("interval_subtotals") ?? []
        let kind: StatsMetric.Kind = keys.contains("orders_count") ? .integer : .currency
        return chartData(for: StatsMetric(kind: kind, keys: keys), intervals: intervals)
    }

    private func chartData(for metric: StatsMetric, intervals: [AnyCodableJSON]) -> [Double] {
        guard !intervals.isEmpty else { return [] }
        let sorted = intervals.enumerated().sorted { lhs, rhs in
            let lhsKey = chartSortKey(for: lhs.element)
            let rhsKey = chartSortKey(for: rhs.element)
            if lhsKey == rhsKey {
                return lhs.offset < rhs.offset
            }
            return lhsKey < rhsKey
        }.map { $0.element }
        return sorted.map { interval in
            let subtotals = interval.assistantObject("subtotals")
            for key in metric.keys {
                if let raw = subtotals?.assistantString(key), let value = Double(raw) {
                    return value
                }
                if let value = subtotals?.assistantInt(key) {
                    return Double(value)
                }
            }
            return 0
        }
    }

    private func chartSortKey(for interval: AnyCodableJSON) -> String {
        if let date = interval.assistantString("date_start"), !date.isEmpty {
            return date
        }
        return interval.assistantString("interval") ?? ""
    }

    func formatDateRange(after: String?, before: String?) -> String? {
        guard let after, let before,
              let startDate = Self.isoDateFormatter.date(from: after),
              let endDate = Self.isoDateFormatter.date(from: before) else {
            return nil
        }
        if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            return Self.rangeDayFormatter.string(from: startDate)
        }
        let startText = Self.rangeDayFormatter.string(from: startDate)
        let endText = Self.rangeDayFormatter.string(from: endDate)
        return "\(startText) - \(endText)"
    }

    private struct StatsCardMapping {
        let topRow: StatsRowMapping
        let bottomRow: StatsRowMapping

        init?(toolName: String) {
            // The orchestrator's synthetic toolName for an analytics_stats card is
            // `analytics_orders`; the orders report already returns all four metrics
            // the 4-metric layout renders.
            guard toolName == AnalyticsOrdersTool.name else {
                return nil
            }
            topRow = StatsRowMapping(
                leadingTitle: Localization.totalSales,
                trailingTitle: Localization.netSales,
                leading: StatsMetric(kind: .currency, keys: ["total_sales", "gross_sales"]),
                trailing: StatsMetric(kind: .currency, keys: ["net_revenue"])
            )
            bottomRow = StatsRowMapping(
                leadingTitle: Localization.totalOrders,
                trailingTitle: Localization.avgOrderValue,
                leading: StatsMetric(kind: .integer, keys: ["orders_count", "num_orders"]),
                trailing: StatsMetric(kind: .currency, keys: ["avg_order_value", "average_order_value"])
            )
        }
    }

    private struct StatsRowMapping {
        let leadingTitle: String
        let trailingTitle: String
        let leading: StatsMetric
        let trailing: StatsMetric
    }

    private struct StatsMetric {
        let kind: Kind
        let keys: [String]

        enum Kind {
            case currency
            case integer
        }
    }

    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let rangeDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private enum Layout {
        static let rowHorizontalPadding: CGFloat = 16
        static let rowVerticalPadding: CGFloat = 12
    }

    private enum Localization {
        static let customerNoEmail = NSLocalizedString(
            "assistant.externalViews.customer.noEmailPlaceholder",
            value: "No email on file",
            comment: "Placeholder shown on the assistant customer row when the customer has no email."
        )
        static let singleOrder = NSLocalizedString(
            "assistant.externalViews.customer.orderCount.singular",
            value: "1 order",
            comment: "Singular orders-count badge on the assistant customer row."
        )
        static let orderCount = NSLocalizedString(
            "assistant.externalViews.customer.orderCount.plural",
            value: "%1$@ orders",
            comment: "Plural orders-count badge on the assistant customer row. %1$@ is the count."
        )
        static let analyticsTitle = NSLocalizedString(
            "assistant.externalViews.stats.shellTitle",
            value: "Analytics",
            comment: "Shell title shared by the assistant revenue and orders analytics cards."
        )
        static let totalSales = NSLocalizedString(
            "assistant.externalViews.stats.totalSales",
            value: "Total Sales",
            comment: "Leading column title on the assistant revenue analytics card."
        )
        static let netSales = NSLocalizedString(
            "assistant.externalViews.stats.netSales",
            value: "Net Sales",
            comment: "Trailing column title on the assistant revenue analytics card."
        )
        static let totalOrders = NSLocalizedString(
            "assistant.externalViews.stats.totalOrders",
            value: "Total Orders",
            comment: "Leading column title on the assistant orders analytics card."
        )
        static let avgOrderValue = NSLocalizedString(
            "assistant.externalViews.stats.avgOrderValue",
            value: "Average Order Value",
            comment: "Trailing column title on the assistant orders analytics card."
        )
        static let metricUnavailable = NSLocalizedString(
            "assistant.externalViews.stats.metricUnavailable",
            value: "-",
            comment: "Placeholder shown on the assistant analytics card when a metric is missing from the tool result."
        )
        static let guestCustomer = NSLocalizedString(
            "assistant.externalViews.order.guestCustomer",
            value: "Guest",
            comment: "Customer name shown on the assistant order card when the order has no registered customer."
        )
        static let registeredCustomerWithID = NSLocalizedString(
            "assistant.externalViews.order.registeredCustomerWithID",
            value: "Customer #%@",
            comment: "Fallback shown on the assistant order card when a registered customer has no billing name and no email on file. %@ is the customer id."
        )
        static let inStock = NSLocalizedString(
            "assistant.externalViews.product.stock.inStock",
            value: "In stock",
            comment: "Stock status badge on the assistant product card."
        )
        static let outOfStock = NSLocalizedString(
            "assistant.externalViews.product.stock.outOfStock",
            value: "Out of stock",
            comment: "Stock status badge on the assistant product card."
        )
        static let onBackorder = NSLocalizedString(
            "assistant.externalViews.product.stock.onBackorder",
            value: "On backorder",
            comment: "Stock status badge on the assistant product card."
        )
        static let stockLeft = NSLocalizedString(
            "assistant.externalViews.product.stock.left",
            value: "%1$@ left",
            comment: "Accessory on the assistant product row when stock quantity is known. %1$@ is the count."
        )
        static let stockCountFormat = NSLocalizedString(
            "assistant.externalViews.product.stock.countFormat",
            value: "%1$@ in stock",
            comment: "Subtitle on the assistant product row inlining the stock count. %1$@ is the count."
        )
        static let singleVariation = NSLocalizedString(
            "assistant.externalViews.product.variations.singular",
            value: "1 variation",
            comment: "Variations badge on the assistant product row when the product has exactly one variation."
        )
        static let variationsCount = NSLocalizedString(
            "assistant.externalViews.product.variations.plural",
            value: "%1$@ variations",
            comment: "Variations badge on the assistant product row for variable products. %1$@ is the count."
        )
    }
}

private extension ISO8601DateFormatter {
    static let assistantWithFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let assistantNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

private extension DateFormatter {
    static let assistantWCLocalFallback: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
