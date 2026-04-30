import SwiftUI

/// Reusable cell that renders a single metric on the home-screen widget.
///
/// Accepts any `MetricPresentable` so the view is testable with stubs and size/family-specific
/// formatting can be swapped by changing the presenter, not the cell. When the metric exposes
/// a `tapURL`, the cell becomes a `Link` so the system handles the deep-link.
///
struct MetricCellView: View {
    let metric: any MetricPresentable

    var body: some View {
        if let url = metric.tapURL {
            Link(destination: url) {
                content
            }
        } else {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            Text(metric.title)
                .statTitleStyle()

            Text(metric.formattedValue)
                .statValueStyle()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension MetricCellView {
    enum Layout {
        static let cardSpacing = 2.0
    }
}

// MARK: - Previews
#if DEBUG
struct MetricCellView_Previews: PreviewProvider {
    private struct PreviewMetric: MetricPresentable {
        let title: String
        let formattedValue: String
    }

    static var previews: some View {
        MetricCellView(metric: PreviewMetric(title: "Total sales", formattedValue: "$12.3k"))
            .padding()
            .background(Color(.brand))
            .previewLayout(.sizeThatFits)
    }
}
#endif
