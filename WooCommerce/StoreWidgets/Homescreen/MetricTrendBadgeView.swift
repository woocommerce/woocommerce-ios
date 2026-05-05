import SwiftUI

/// Compact trailing badge that pairs a chevron with the formatted percentage delta.
/// Color encodes direction (green up / red down). Hidden whenever the parent
/// `MetricPresentable` returns `nil` for `trend`.
///
struct MetricTrendBadgeView: View {
    let trend: MetricTrendPresentation

    var body: some View {
        HStack(spacing: Layout.spacing) {
            Image(systemName: symbolName)
                .font(Layout.trendIndicatorFont)
                .minimumScaleFactor(0.7)
            Text(trend.formattedPercentage)
                .font(Layout.trendTextFont)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(color)
        .accessibilityLabel(accessibilityLabel)
    }
}

private extension MetricTrendBadgeView {
    var symbolName: String {
        switch trend.direction {
        case .up:
            return "arrowtriangle.up.fill"
        case .down:
            return "arrowtriangle.down.fill"
        }
    }

    var color: Color {
        switch trend.direction {
        case .up:
            return Color(.systemGreen)
        case .down:
            return Color(.systemRed)
        }
    }

    var accessibilityLabel: Text {
        switch trend.direction {
        case .up:
            return Text(Localization.increased(trend.formattedPercentage))
        case .down:
            return Text(Localization.decreased(trend.formattedPercentage))
        }
    }
}

private extension MetricTrendBadgeView {
    enum Layout {
        static let spacing = 2.0
        static let trendTextFont: Font = .system(size: 9, weight: .bold)
        static let trendIndicatorFont: Font = .system(size: 7, weight: .bold)
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
    }
}
