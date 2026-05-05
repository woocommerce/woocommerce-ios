import Charts
import SwiftUI

/// Compact trailing chart for `MetricCellView`. Two render styles:
/// - `.sparkline` — thin line with a fading area fill (iOS Stocks app style).
/// - `.bar` — one bar per interval. Reserved for the wider main-metric row.
///
/// Color is driven by `tone` — green for upward trends, red for downward, neutral mint /
/// periwinkle when the trend is unknown. Edit `Palette` to retune all gradients in one place.
///
/// Caller sizes via `.frame(...)` and gates on `count > 1`.
///
struct MetricChartView: View {
    let data: [MetricChartPoint]
    private let style: Style
    private let tone: Tone

    init(data: [MetricChartPoint], style: Style = .sparkline, tone: Tone = .neutral) {
        self.data = data
        self.style = style
        self.tone = tone
    }

    var body: some View {
        Chart(Array(data.enumerated()), id: \.offset) { index, point in
            switch style {
            case .bar:
                barMark(index: index, point: point)
            case .sparkline:
                sparklineMarks(index: index, point: point)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        // Floor prevents `chartYScale` from collapsing to `0...0` on flat-zero series.
        .chartYScale(domain: 0...max(maxValue, Constants.minYDomainCeiling))
        .chartPlotStyle { plot in
            plot.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Marks

private extension MetricChartView {
    /// Single bar at `index` for the `.bar` style.
    func barMark(index: Int, point: MetricChartPoint) -> some ChartContent {
        BarMark(
            // Categorical x — numeric x makes BarMark widths size off the data range and
            // overlap once the slot is narrow.
            x: .value("Index", String(index)),
            y: .value("Value", max(point.value, 0)),
            width: .ratio(Constants.barWidthRatio)
        )
        .foregroundStyle(lineGradient)
        .cornerRadius(Constants.barCornerRadius)
    }

    /// Area + line pair for the `.sparkline` style. Both share the same interpolation so
    /// the area fill follows the smoothed line shape exactly.
    @ChartContentBuilder
    func sparklineMarks(index: Int, point: MetricChartPoint) -> some ChartContent {
        AreaMark(
            x: .value("Index", index),
            y: .value("Value", max(point.value, 0))
        )
        .foregroundStyle(areaGradient)
        .interpolationMethod(.monotone)

        LineMark(
            x: .value("Index", index),
            y: .value("Value", max(point.value, 0))
        )
        .foregroundStyle(lineGradient)
        .lineStyle(StrokeStyle(lineWidth: Constants.sparklineLineWidth,
                               lineCap: .round,
                               lineJoin: .round))
        // `.monotone` softens the joins without overshooting peaks the way `.catmullRom`
        // does on spiky data.
        .interpolationMethod(.monotone)
    }
}

private extension MetricChartView {
    var maxValue: Double {
        data.map(\.value).max() ?? 0
    }

    /// Gradient applied to the bar fill / sparkline stroke. Lighter at the top, darker at
    /// the base — matches the iOS Stocks reading direction (peaks read brighter).
    var lineGradient: LinearGradient {
        switch tone {
        case .up:
            return LinearGradient(
                colors: [
                    Palette.upHigh,
                    Palette.upLow
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .down:
            return LinearGradient(
                colors: [
                    Palette.downHigh,
                    Palette.downLow
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .neutral:
            return LinearGradient(
                colors: [
                    Palette.neutralHigh,
                    Palette.neutralLow
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    /// Gradient applied to the sparkline `AreaMark`. Solid-ish at the top fading to fully
    /// transparent at the base, so the fill reads as a soft glow under the line.
    var areaGradient: LinearGradient {
        let top: Color
        switch tone {
        case .up: top = Palette.upHigh
        case .down: top = Palette.downHigh
        case .neutral: top = Palette.neutralHigh
        }
        return LinearGradient(
            colors: [top.opacity(Constants.areaTopOpacity), top.opacity(0.05)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension MetricChartView {
    enum Style {
        case sparkline
        case bar
    }

    enum Tone {
        case up
        case down
        case neutral
    }
}

private extension MetricChartView {
    /// Single source of truth for chart colors — tweak here to retune both styles.
    enum Palette {
        // Green (uptrend): dark green → light mint
        static let upHigh = Color(red: 0.45, green: 0.95, blue: 0.70)
        static let upLow = Color(red: 0.10, green: 0.55, blue: 0.30)

        // Red (downtrend): dark red → light coral
        static let downHigh = Color(red: 1.00, green: 0.55, blue: 0.55)
        static let downLow = Color(red: 0.60, green: 0.12, blue: 0.12)

        // Neutral fallback when trend direction is unknown.
        static let neutralHigh = Color(red: 0.45, green: 0.95, blue: 0.78)
        static let neutralLow = Color(red: 0.55, green: 0.65, blue: 1.00)
    }

    enum Constants {
        static let barWidthRatio = 0.55
        static let barCornerRadius = 1.0
        static let sparklineLineWidth = 1.5
        static let areaTopOpacity = 0.75
        static let minYDomainCeiling = 1.0
    }
}

#if DEBUG
private func sampleData() -> [MetricChartPoint] {
    let now = Date()
    return (0..<24).map { hour in
        MetricChartPoint(
            date: now.addingTimeInterval(TimeInterval(hour * 3600)),
            value: Double.random(in: 0...10) + max(0, 12 - Double(abs(12 - hour)))
        )
    }
}

#Preview("Sparkline up") {
    MetricChartView(data: sampleData(), style: .sparkline, tone: .up)
        .frame(width: 60, height: 20)
        .padding()
        .background(Color(.brand))
}

#Preview("Sparkline down") {
    MetricChartView(data: sampleData(), style: .sparkline, tone: .down)
        .frame(width: 60, height: 20)
        .padding()
        .background(Color(.brand))
}

#Preview("Bar up") {
    MetricChartView(data: sampleData(), style: .bar, tone: .up)
        .frame(width: 200, height: 40)
        .padding()
        .background(Color(.brand))
}

#Preview("Bar down") {
    MetricChartView(data: sampleData(), style: .bar, tone: .down)
        .frame(width: 200, height: 40)
        .padding()
        .background(Color(.brand))
}
#endif
