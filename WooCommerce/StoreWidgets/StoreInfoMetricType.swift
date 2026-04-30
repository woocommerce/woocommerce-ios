import Foundation

/// Catalog of metrics that store widgets can surface.
///
/// The raw value is a stable, persistence-safe identifier — it is written into App Group storage
/// and (later) into `AppIntentConfiguration` options. Do not rename cases without a migration.
///
enum StoreInfoMetricType: String, CaseIterable, Hashable {
    // ⚠️ Don't rename these raw values without a migration —
    // they are persisted to App Group storage and AppIntent configuration.
    case revenue
    case netSales
    case orders
    case itemsSold
    case visitors
    case conversion
    case averageOrderValue

    /// Localized user-facing title rendered in the metric cell.
    ///
    var displayName: String {
        switch self {
        case .revenue: return Localization.revenue
        case .netSales: return Localization.netSales
        case .orders: return Localization.orders
        case .itemsSold: return Localization.itemsSold
        case .visitors: return Localization.visitors
        case .conversion: return Localization.conversion
        case .averageOrderValue: return Localization.averageOrderValue
        }
    }

    /// How the raw metric value should be formatted for display.
    ///
    enum Unit {
        case currency
        case count
        case percentage
    }

    var unit: Unit {
        switch self {
        case .revenue, .netSales, .averageOrderValue: return .currency
        case .orders, .itemsSold, .visitors: return .count
        case .conversion: return .percentage
        }
    }

    /// Whether the metric's data source requires WPCOM/Jetpack endpoints.
    /// Used by the metric picker to filter options for self-hosted users.
    ///
    var requiresWPCom: Bool {
        switch self {
        case .visitors, .conversion: return true
        case .revenue, .netSales, .orders, .itemsSold, .averageOrderValue: return false
        }
    }
}

// MARK: - Localization

private extension StoreInfoMetricType {
    // Keys here intentionally reuse the previous per-view keys where the English value
    // is unchanged, so existing GlotPress translations carry over without a regression.
    // Truly new metrics (netSales, itemsSold, averageOrderValue) use new `storeWidgets.metric.*` keys.
    enum Localization {
        static let revenue = AppLocalizedString(
            "storeWidgets.infoView.totalSales",
            value: "Total sales",
            comment: "Revenue metric title — gross revenue including taxes and shipping."
        )
        static let netSales = AppLocalizedString(
            "storeWidgets.metric.netSales",
            value: "Net sales",
            comment: "Net sales metric title — revenue excluding tax, shipping, and refunds."
        )
        static let orders = AppLocalizedString(
            "storeWidgets.infoView.orders",
            value: "Orders",
            comment: "Orders metric title for the store info widget."
        )
        static let itemsSold = AppLocalizedString(
            "storeWidgets.metric.itemsSold",
            value: "Items sold",
            comment: "Items sold metric title — total units sold in the period."
        )
        static let visitors = AppLocalizedString(
            "storeWidgets.infoView.visitors",
            value: "Visitors",
            comment: "Visitors metric title for the store info widget."
        )
        static let conversion = AppLocalizedString(
            "storeWidgets.infoView.conversion",
            value: "Conversion",
            comment: "Conversion rate metric title for the store info widget."
        )
        static let averageOrderValue = AppLocalizedString(
            "storeWidgets.metric.averageOrderValue",
            value: "Average order value",
            comment: "Average order value (AOV) metric title for the store info widget."
        )
    }
}
