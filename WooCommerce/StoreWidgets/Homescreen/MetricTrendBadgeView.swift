import SwiftUI

/// Compact trailing badge that pairs a chevron with the formatted percentage delta.
/// Color encodes direction (green up / red down / gray flat). On `.flat` the percentage
/// text is suppressed and only the dash indicator renders. Hidden whenever the parent
/// `MetricPresentable` returns `nil` for `trend`.
///
/// `size` mirrors the parent text stack's `MetricCellTextSize` so the badge scales
/// alongside the title and value.
///
struct MetricTrendBadgeView: View {
    @Environment(\.storeWidgetTheme) private var theme

    let trend: MetricTrendPresentation
    let size: MetricCellTextSize

    var body: some View {
        HStack(spacing: Layout.spacing) {
            indicator
            if trend.direction != .flat {
                text
            }
        }
        .foregroundStyle(color)
        .accessibilityLabel(accessibilityLabel)
    }
}

private extension MetricTrendBadgeView {
    @ViewBuilder
    var indicator: some View {
        switch size {
        case .regular:
            Image(systemName: symbolName)
                .statTrendIndicatorStyle()
                .minimumScaleFactor(0.7)
        case .large:
            Image(systemName: symbolName)
                .statTrendIndicatorLargeStyle()
                .minimumScaleFactor(0.7)
        }
    }

    @ViewBuilder
    var text: some View {
        switch size {
        case .regular:
            Text(trend.formattedPercentage)
                .statTrendTextStyle()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        case .large:
            Text(trend.formattedPercentage)
                .statTrendTextLargeStyle()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

private extension MetricTrendBadgeView {
    var symbolName: String {
        switch trend.direction {
        case .up:
            return "arrowtriangle.up.fill"
        case .down:
            return "arrowtriangle.down.fill"
        case .flat:
            return "minus"
        }
    }

    var color: Color {
        switch (theme, trend.direction) {
        case (.default, .up):
            return Color(red: 0.55, green: 0.88, blue: 0.70)
        case (.default, .down):
            return Color(red: 0.95, green: 0.65, blue: 0.70)
        case (.sameAsSystem, .up):
            return Color(.systemGreen)
        case (.sameAsSystem, .down):
            return Color(.systemRed)
        case (_, .flat):
            return Color(.systemGray)
        }
    }

    var accessibilityLabel: Text {
        switch trend.direction {
        case .up:
            return Text(Localization.increased(trend.formattedPercentage))
        case .down:
            return Text(Localization.decreased(trend.formattedPercentage))
        case .flat:
            return Text(Localization.unchanged)
        }
    }
}

private extension MetricTrendBadgeView {
    enum Layout {
        static let spacing = 2.0
    }

    enum Localization {
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

        static let unchanged = AppLocalizedString(
            "storeWidgets.metricTrend.unchanged",
            value: "Unchanged",
            comment: "Accessibility label for a metric trend that did not change between the current and previous period."
        )
    }
}
