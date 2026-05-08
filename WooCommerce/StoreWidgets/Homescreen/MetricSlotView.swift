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
            MetricSlotPlaceholderView(minHeight: placeholderMinHeight)
        }
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
