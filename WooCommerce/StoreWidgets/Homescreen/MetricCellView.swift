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

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(metric.formattedValue)
                    .statValueStyle()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let trend = metric.trend {
                    Spacer(minLength: Layout.badgeSpacing)
                    MetricTrendBadgeView(trend: trend)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension MetricCellView {
    enum Layout {
        static let cardSpacing = 2.0
        static let badgeSpacing = 16.0
    }
}

/// Compact trailing badge that pairs a chevron with the formatted percentage delta.
/// Color encodes direction (green up / red down). Hidden whenever the parent
/// `MetricPresentable` returns `nil` for `trend`.
///
private struct MetricTrendBadgeView: View {
    let trend: MetricTrendPresentation

    var body: some View {
        HStack(spacing: Layout.spacing) {
            Image(systemName: symbolName)
                .font(.caption2.weight(.bold))
            Text(trend.formattedPercentage)
                .font(.caption2.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(color)
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel(accessibilityLabel)
    }

    private var symbolName: String {
        switch trend.direction {
        case .up:
            return "chevron.up"
        case .down:
            return "chevron.down"
        }
    }

    private var color: Color {
        switch trend.direction {
        case .up:
            return Color(.systemGreen)
        case .down:
            return Color(.systemRed)
        }
    }

    private var accessibilityLabel: Text {
        switch trend.direction {
        case .up:
            return Text(Localization.increased(trend.formattedPercentage))
        case .down:
            return Text(Localization.decreased(trend.formattedPercentage))
        }
    }

    private enum Localization {
        static func increased(_ value: String) -> LocalizedString {
            let format = AppLocalizedString(
                "storeWidgets.metricTrend.increased",
                value: "Increased by %1$@",
                comment: "Accessibility label for an upward metric trend. %1$@ is the formatted percentage change."
            )
            return LocalizedString.localizedStringWithFormat(format, value)
        }

        static func decreased(_ value: String) -> LocalizedString {
            let format = AppLocalizedString(
                "storeWidgets.metricTrend.decreased",
                value: "Decreased by %1$@",
                comment: "Accessibility label for a downward metric trend. %1$@ is the formatted percentage change."
            )
            return LocalizedString.localizedStringWithFormat(format, value)
        }
    }

    private enum Layout {
        static let spacing = 1.0
    }
}

// MARK: - Previews
#if DEBUG
struct MetricCellView_Previews: PreviewProvider {
    private struct PreviewMetric: MetricPresentable {
        let title: String
        let formattedValue: String
        var trend: MetricTrendPresentation?
    }

    static var previews: some View {
        Group {
            MetricCellView(metric: PreviewMetric(title: "Total sales", formattedValue: "$12.3k"))
                .previewDisplayName("Without trend")

            MetricCellView(metric: PreviewMetric(title: "Total sales",
                                                 formattedValue: "$12.3k",
                                                 trend: .init(direction: .up, formattedPercentage: "6%")))
                .previewDisplayName("With trend up")

            MetricCellView(metric: PreviewMetric(title: "Total sales",
                                                 formattedValue: "$12.3k",
                                                 trend: .init(direction: .down, formattedPercentage: "12%")))
                .previewDisplayName("With trend down")
        }
        .frame(width: 180)
        .padding()
        .background(Color(.brand))
        .previewLayout(.sizeThatFits)
    }
}
#endif
