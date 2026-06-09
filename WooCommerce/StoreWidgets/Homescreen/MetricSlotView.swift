import SwiftUI

struct MetricSlotView<MetricContent: View>: View {
    private let slot: StoreInfoMetricSlot
    private let placeholderMinHeight: Double
    private let metricContent: (StoreInfoMetric) -> MetricContent

    init(
        slot: StoreInfoMetricSlot,
        placeholderMinHeight: Double,
        @ViewBuilder metricContent: @escaping (StoreInfoMetric) -> MetricContent
    ) {
        self.slot = slot
        self.placeholderMinHeight = placeholderMinHeight
        self.metricContent = metricContent
    }

    var body: some View {
        switch slot {
        case .metric(let metric):
            metricContent(metric)
        case .empty:
            MetricSlotEmptyView(minHeight: placeholderMinHeight)
        }
    }
}

struct MetricSlotEmptyView: View {
    let minHeight: Double

    var body: some View {
        Text(StoreInfoFormatter.Constants.valuePlaceholderText)
            .statValueStyle()
            .opacity(Layout.placeholderOpacity)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .center)
            .accessibilityHidden(true)
    }

    private enum Layout {
        static let placeholderOpacity = 0.30
    }
}

struct MetricSlotPlaceholderView: View {
    let minHeight: Double

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .accessibilityHidden(true)
    }
}
