import SwiftUI

/// Renders an ordered list of metrics in a two-column grid.
///
struct StoreInfoMetricsGrid: View {
    enum LeadingMetricStyle {
        case standard
        case large
    }

    private let leadingSlot: StoreInfoMetricSlot?
    private let rows: [[StoreInfoMetricSlot]]
    private let dateRange: StoreStatsWidgetDateRange?

    init(
        metricSlots: [StoreInfoMetricSlot],
        dateRange: StoreStatsWidgetDateRange? = nil,
        leadingMetricStyle: LeadingMetricStyle = .standard
    ) {
        self.init(slots: metricSlots, dateRange: dateRange, leadingMetricStyle: leadingMetricStyle)
    }

    private init(slots: [StoreInfoMetricSlot], dateRange: StoreStatsWidgetDateRange?, leadingMetricStyle: LeadingMetricStyle) {
        self.dateRange = dateRange
        switch leadingMetricStyle {
        case .standard:
            self.leadingSlot = nil
            self.rows = Self.chunkedRows(from: slots)
        case .large:
            self.leadingSlot = slots.first
            self.rows = Self.chunkedRows(from: Array(slots.dropFirst()))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            if let leadingSlot {
                leadingSlotView(leadingSlot)
                    .padding(.bottom, Layout.leadingCellAdditionalBottomPadding)
            }

            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: Layout.columnSpacing) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, slot in
                        regularSlotView(slot)
                    }

                    if row.count < Layout.metricsPerRow {
                        ForEach(0..<(Layout.metricsPerRow - row.count), id: \.self) { _ in
                            MetricSlotPlaceholderView(minHeight: Layout.regularSlotMinHeight)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func regularSlotView(_ slot: StoreInfoMetricSlot) -> some View {
        MetricSlotView(slot: slot, placeholderMinHeight: Layout.regularSlotMinHeight) { metric in
            MetricCellView(metric: WidgetMetricPresenter(metric: metric, dateRange: dateRange))
        }
    }

    @ViewBuilder
    private func leadingSlotView(_ slot: StoreInfoMetricSlot) -> some View {
        MetricSlotView(slot: slot, placeholderMinHeight: Layout.leadingSlotMinHeight) { metric in
            MetricLargeCellView(metric: WidgetMetricPresenter(metric: metric, dateRange: dateRange))
        }
    }

    private static func chunkedRows(from slots: [StoreInfoMetricSlot]) -> [[StoreInfoMetricSlot]] {
        stride(from: 0, to: slots.count, by: Layout.metricsPerRow).map { start in
            Array(slots[start..<min(start + Layout.metricsPerRow, slots.count)])
        }
    }

    private enum Layout {
        static let sectionSpacing = 8.0
        static let metricsPerRow = 2
        static let columnSpacing = 16.0
        static let leadingCellAdditionalBottomPadding = 8.0
        static let regularSlotMinHeight = 36.0
        static let leadingSlotMinHeight = 70.0
    }
}

// MARK: - Previews
#if DEBUG
struct StoreInfoMetricsGrid_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StoreInfoMetricsGrid(metricSlots: StoreInfoMetricsView_Previews.exampleData.metricSlots)
                .previewDisplayName("Standard")

            StoreInfoMetricsGrid(metricSlots: StoreInfoMetricsView_Previews.fullCatalogData.metricSlots,
                                 leadingMetricStyle: .large)
                .previewDisplayName("Large leading metric")
        }
        .padding()
        .background(Color(.brand))
        .previewLayout(.sizeThatFits)
    }
}
#endif
