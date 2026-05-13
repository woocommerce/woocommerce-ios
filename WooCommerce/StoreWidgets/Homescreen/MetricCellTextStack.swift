import SwiftUI

/// Where the trend badge renders relative to the title and value rows.
enum MetricCellTrendPlacement {
    case alongsideTitle
    case alongsideValue
}

/// Text size variant for `MetricCellTextStack`. Selects between regular and large
/// font modifiers; does not affect positioning.
enum MetricCellTextSize {
    case regular
    case large
}

/// Wraps cell content in a `Link` when the metric provides a `tapURL`; otherwise
/// renders the content as-is.
struct MetricCellLink<Content: View>: View {
    let destination: URL?
    let content: Content

    init(destination: URL?, @ViewBuilder content: () -> Content) {
        self.destination = destination
        self.content = content()
    }

    var body: some View {
        if let destination {
            Link(destination: destination) {
                content
            }
        } else {
            content
        }
    }
}

/// Renders title + value + trend for a metric. Chart placement is owned by the
/// parent cell view, not by this stack.
///
/// Sizes to intrinsic width — the parent cell decides whether the stack should
/// expand (`.frame(maxWidth: .infinity, alignment: .leading)` at the call site).
struct MetricCellTextStack: View {
    let metric: any MetricPresentable
    let trendPlacement: MetricCellTrendPlacement
    let size: MetricCellTextSize

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            titleRow
            valueRow
        }
    }

    @ViewBuilder
    private var titleRow: some View {
        HStack(spacing: Layout.titleRowSpacing) {
            title
            if trendPlacement == .alongsideTitle, let trend = metric.trend {
                MetricTrendBadgeView(trend: trend, size: size)
            }
        }
    }

    @ViewBuilder
    private var valueRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Layout.valueAndTrendSpacing) {
            value
            if trendPlacement == .alongsideValue, let trend = metric.trend {
                MetricTrendBadgeView(trend: trend, size: size)
            }
        }
    }

    @ViewBuilder
    private var title: some View {
        switch size {
        case .regular:
            Text(metric.title)
                .statTitleStyle()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        case .large:
            Text(metric.title)
                .statTitleLargeStyle()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    @ViewBuilder
    private var value: some View {
        switch size {
        case .regular:
            Text(metric.formattedValue)
                .statValueStyle()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .layoutPriority(1)
        case .large:
            Text(metric.formattedValue)
                .statValueLargeStyle()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .layoutPriority(1)
        }
    }

    private enum Layout {
        static let cardSpacing = 2.0
        static let titleRowSpacing = 6.0
        static let valueAndTrendSpacing = 5.0
    }
}
