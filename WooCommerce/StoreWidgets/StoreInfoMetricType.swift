import AppIntents
import Foundation

/// Catalog of metrics that store widgets can surface, plus the `.none` sentinel used to
/// preserve an explicitly hidden widget slot.
///
/// The raw value is the stable, persistence-safe identifier — written into App Group storage
/// and into `AppIntentConfiguration` options (the intent system uses it as the entity `id`).
/// Do not rename cases without a migration.
///
enum StoreInfoMetricType: String, CaseIterable, Hashable {
    // ⚠️ Don't rename these raw values without a migration —
    // they are persisted to App Group storage and AppIntent configuration.
    case none
    case revenue
    case netSales
    case orders
    case itemsSold
    case visitors
    case conversion
    case averageOrderValue

    /// Picker options, in display order. The sentinel is first so users can clear any slot.
    static let pickerCases: [StoreInfoMetricType] = [.none] + catalogCases

    /// Concrete metrics that can be fetched and rendered.
    static let catalogCases: [StoreInfoMetricType] = [
        .revenue, .orders, .itemsSold, .averageOrderValue,
        .netSales, .visitors, .conversion
    ]

    /// Localized user-facing title rendered in the metric cell.
    ///
    var displayName: String {
        switch self {
        case .none: return Localization.none
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
        case .none: return .count
        }
    }

    /// Whether the metric can render an interval chart from `OrderStatsV4.intervals`.
    ///
    /// Visitors and conversion are sourced from site summary stats, which currently return
    /// aggregate values only.
    var supportsChart: Bool {
        switch self {
        case .revenue, .netSales, .averageOrderValue, .orders, .itemsSold:
            return true
        case .visitors, .conversion, .none:
            return false
        }
    }
}

// MARK: - AppEntity

/// Surfaces the catalog as the element type for the `metrics` parameter on
/// `StoreStatsConfigurationIntent`. Modeled as `AppEntity` because only the entity-array
/// `IntentParameter` initializer accepts the family-keyed `size:` map.
///
/// Intent-UI strings here are English literals; the AppIntents metadata processor extracts
/// them at build time and rejects runtime-evaluated expressions, and the project policy of
/// "no `.strings` files in extensions" rules out the obvious workaround. Localization is
/// tracked as a follow-up; in-widget cells continue to use `displayName` (host-bundle,
/// fully localized).
///
extension StoreInfoMetricType: AppEntity {
    var id: String { rawValue }

    var displayRepresentation: DisplayRepresentation {
        switch self {
        case .none: return "None"
        case .revenue: return "Total sales"
        case .netSales: return "Net sales"
        case .orders: return "Orders"
        case .itemsSold: return "Items sold"
        case .visitors: return "Visitors"
        case .conversion: return "Conversion"
        case .averageOrderValue: return "Average order value"
        }
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Metric")
    }

    static var defaultQuery: AvailableMetricsQuery { AvailableMetricsQuery() }
}

// MARK: - Localization

private extension StoreInfoMetricType {
    // Keys here intentionally reuse the previous per-view keys where the English value
    // is unchanged, so existing GlotPress translations carry over without a regression.
    // Truly new metrics (netSales, itemsSold, averageOrderValue) use new `storeWidgets.metric.*` keys.
    enum Localization {
        static let none = AppLocalizedString(
            "storeWidgets.metric.none",
            value: "None",
            comment: "Metric picker sentinel that hides the corresponding widget metric slot."
        )
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
        // Shorter than the picker's "Average order value" so it doesn't shrink-to-fit on
        // narrow cells (`.systemSmall` / 2-column `.systemMedium`). The full label is kept on
        // the AppEntity `displayRepresentation` for the configuration picker.
        static let averageOrderValue = AppLocalizedString(
            "storeWidgets.metric.averageOrderValueShort",
            value: "Avg. order",
            comment: "Compact title for the average order value metric, shown on the widget cell."
        )
    }
}
