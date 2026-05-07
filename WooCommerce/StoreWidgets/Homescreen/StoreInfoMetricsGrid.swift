import SwiftUI

/// Renders an ordered list of metrics in a two-column grid.
///
/// Operates on the presentation protocol so the layout is decoupled from the
/// concrete `StoreInfoMetric` type.
struct StoreInfoMetricsGrid: View {
    enum LeadingMetricStyle {
        case standard
        case large
    }

    private let leadingMetric: (any MetricPresentable)?
    private let rows: [[any MetricPresentable]]

    init(metrics: [any MetricPresentable], leadingMetricStyle: LeadingMetricStyle = .standard) {
        switch leadingMetricStyle {
        case .standard:
            self.leadingMetric = nil
            self.rows = Self.chunkedRows(from: metrics)
        case .large:
            self.leadingMetric = metrics.first
            self.rows = Self.chunkedRows(from: Array(metrics.dropFirst()))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            if let leadingMetric {
                MetricLargeCellView(metric: leadingMetric)
                    .padding(.bottom, Layout.leadingCellAdditionalBottomPadding)
            }

            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: Layout.columnSpacing) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, metric in
                        MetricCellView(metric: metric)
                    }

                    if row.count < Layout.metricsPerRow {
                        ForEach(0..<(Layout.metricsPerRow - row.count), id: \.self) { _ in
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
        }
    }

    private static func chunkedRows(from metrics: [any MetricPresentable]) -> [[any MetricPresentable]] {
        stride(from: 0, to: metrics.count, by: Layout.metricsPerRow).map { start in
            Array(metrics[start..<min(start + Layout.metricsPerRow, metrics.count)])
        }
    }

    private enum Layout {
        static let sectionSpacing = 8.0
        static let metricsPerRow = 2
        static let columnSpacing = 16.0
        static let leadingCellAdditionalBottomPadding = 8.0
    }
}

// MARK: - Previews
#if DEBUG
struct StoreInfoMetricsGrid_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StoreInfoMetricsGrid(metrics: StoreInfoMetricsView_Previews.exampleData.metrics)
                .previewDisplayName("Standard")

            StoreInfoMetricsGrid(metrics: StoreInfoMetricsView_Previews.fullCatalogData.metrics,
                                 leadingMetricStyle: .large)
                .previewDisplayName("Large leading metric")
        }
        .padding()
        .background(Color(.brand))
        .previewLayout(.sizeThatFits)
    }
}
#endif
