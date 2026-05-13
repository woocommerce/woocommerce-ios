import SwiftUI

/// Compact trailing badge that pairs an indicator with the formatted percentage delta.
/// On `.flat` the percentage text is suppressed and only the dash indicator renders.
/// Hidden whenever the parent `MetricPresentable` returns `nil` for `trend`.
///
/// `size` mirrors the parent text stack's `MetricCellTextSize` so the badge scales
/// alongside the title and value.
///
struct MetricTrendBadgeView: View {
    let trend: MetricTrendPresentation
    let size: MetricCellTextSize
    private let style: Style

    init(trend: MetricTrendPresentation, size: MetricCellTextSize, style: Style = .directionalColor) {
        self.trend = trend
        self.size = size
        self.style = style
    }

    var body: some View {
        HStack(spacing: style.spacing) {
            indicator
            if trend.direction != .flat {
                text
            }
        }
        .foregroundStyle(color)
        .accessibilityElement(children: .ignore)
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
        Self.symbolName(for: trend.direction)
    }

    var color: Color {
        style.color(for: trend.direction)
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

    static func symbolName(for direction: MetricTrendPresentation.Direction) -> String {
        switch direction {
        case .up:
            return "arrowtriangle.up.fill"
        case .down:
            return "arrowtriangle.down.fill"
        case .flat:
            return "minus"
        }
    }
}

extension MetricTrendBadgeView {
    enum Style {
        case directionalColor
        case onPrimary

        fileprivate var spacing: Double {
            switch self {
            case .directionalColor:
                return 2.0
            case .onPrimary:
                return 4.0
            }
        }

        fileprivate func color(for direction: MetricTrendPresentation.Direction) -> Color {
            switch self {
            case .directionalColor:
                return directionalColor(for: direction)
            case .onPrimary:
                return Color.primary.opacity(0.82)
            }
        }

        private func directionalColor(for direction: MetricTrendPresentation.Direction) -> Color {
            switch direction {
            case .up:
                return Color(.systemGreen)
            case .down:
                return Color(.systemRed)
            case .flat:
                return Color(.systemGray)
            }
        }
    }
}

private extension MetricTrendBadgeView {
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
