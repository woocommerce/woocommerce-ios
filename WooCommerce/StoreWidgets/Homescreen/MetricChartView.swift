import Charts
import SwiftUI

/// Compact trailing chart for `MetricCellView`. Three render styles:
/// - `.sparkline` — thin line with a fading area fill (iOS Stocks app style).
/// - `.bar` — one bar per interval. Reserved for the wider main-metric row.
/// - `.barOnPrimary` — monochrome bars on lock-screen/accessory backgrounds.
///
/// Color is driven by `tone` — green for upward trends, red for downward, neutral mint /
/// periwinkle when the trend is unknown. `.barOnPrimary` ignores `tone` and uses primary
/// foreground opacity. Edit `Palette` to retune all gradients in one place.
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
        GeometryReader { proxy in
            Chart(Array(data.enumerated()), id: \.offset) { index, point in
                switch style {
                case .bar, .barOnPrimary:
                    barMark(
                        index: index,
                        point: point,
                        cornerRadius: barCornerRadius(chartWidth: proxy.size.width)
                    )
                case .sparkline:
                    sparklineMarks(index: index, point: point)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: 0...yDomainMax)
            .chartPlotStyle { plot in
                plot
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(chartBackground)
            }
            .accessibilityHidden(true)
        }
    }
}

// MARK: - Marks

private extension MetricChartView {
    /// Single bar at `index` for the `.bar` style.
    ///
    /// Floors `y` to `barMinHeight` so a zero value renders as a small pill at the
    /// baseline rather than disappearing entirely. Zero bars also use a muted tone
    /// color so they read as "no data" rather than a real low value.
    ///
    /// `cornerRadius` is half the rendered bar width so tops are fully rounded.
    ///
    func barMark(index: Int, point: MetricChartPoint, cornerRadius: Double) -> some ChartContent {
        BarMark(
            // Categorical x — numeric x makes BarMark widths size off the data range and
            // overlap once the slot is narrow.
            x: .value("Index", String(index)),
            y: .value("Value", max(point.value, barMinHeight)),
            width: .ratio(barWidthRatio)
        )
        .foregroundStyle(barFillStyle(for: point))
        .cornerRadius(cornerRadius)
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

    /// Floor for the y-domain. Prevents `chartYScale` from collapsing to `0...0`
    /// on flat-zero series, and gives `barMinHeight` a stable reference.
    var yDomainMax: Double {
        max(maxValue, Constants.minYDomainCeiling)
    }

    /// Minimum bar height in data units, expressed as a fraction of the y-domain.
    /// Bars below this floor render as a small baseline pill instead of vanishing.
    var barMinHeight: Double {
        yDomainMax * barMinHeightRatio
    }

    /// Approximate rendered bar width derived from the chart's outer width. Used to
    /// pick a corner radius equal to half the bar width so tops are fully rounded.
    /// Axis-hidden charts have negligible plot insets, so this is close enough.
    func barCornerRadius(chartWidth: Double) -> Double {
        guard !data.isEmpty, chartWidth > 0 else { return 0 }
        let barWidth = chartWidth / Double(data.count) * barWidthRatio
        return barWidth / 2
    }

    var barWidthRatio: Double {
        switch style {
        case .barOnPrimary:
            return Constants.onPrimaryBarWidthRatio
        case .bar, .sparkline:
            return Constants.barWidthRatio
        }
    }

    var barMinHeightRatio: Double {
        switch style {
        case .barOnPrimary:
            return Constants.onPrimaryBarMinHeightRatio
        case .bar, .sparkline:
            return Constants.barMinHeightRatio
        }
    }

    func barFillStyle(for point: MetricChartPoint) -> AnyShapeStyle {
        let isZero = point.value <= 0
        switch style {
        case .barOnPrimary:
            let opacity = isZero ? Constants.onPrimaryZeroBarOpacity : Constants.onPrimaryBarOpacity
            return AnyShapeStyle(Color.primary.opacity(opacity))
        case .bar, .sparkline:
            return isZero ? AnyShapeStyle(zeroBarColor) : AnyShapeStyle(lineGradient)
        }
    }

    @ViewBuilder
    var chartBackground: some View {
        if style == .barOnPrimary {
            MetricChartReferenceLines()
        }
    }

    /// Solid color for zero-value bars — uses the deepest shade of the tone palette
    /// so the dot reads as darker than the dark end of the regular bar gradient.
    var zeroBarColor: Color {
        switch tone {
        case .up: return Palette.upDeep
        case .down: return Palette.downDeep
        case .neutral: return Palette.neutralDeep
        }
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
        case barOnPrimary
    }

    enum Tone {
        case up
        case down
        case neutral
    }
}

private extension MetricChartView {
    /// Single source of truth for chart colors — tweak here to retune both styles.
    /// `*Deep` shades are reserved for zero-value bars and sit a step darker than the
    /// dark end of each gradient.
    enum Palette {
        // Green (uptrend): dark green → light mint
        static let upHigh = Color(red: 0.45, green: 0.95, blue: 0.70)
        static let upLow = Color(red: 0.10, green: 0.55, blue: 0.30)
        static let upDeep = Color(red: 0.07, green: 0.40, blue: 0.22)

        // Red (downtrend): dark red → light coral
        static let downHigh = Color(red: 1.00, green: 0.55, blue: 0.55)
        static let downLow = Color(red: 0.60, green: 0.12, blue: 0.12)
        static let downDeep = Color(red: 0.45, green: 0.09, blue: 0.09)

        // Neutral fallback when trend direction is unknown.
        static let neutralHigh = Color(red: 0.45, green: 0.95, blue: 0.78)
        static let neutralLow = Color(red: 0.55, green: 0.65, blue: 1.00)
        static let neutralDeep = Color(red: 0.40, green: 0.48, blue: 0.75)
    }

    enum Constants {
        static let barWidthRatio = 0.87
        static let barMinHeightRatio = 0.02
        static let onPrimaryBarWidthRatio = 0.65
        static let onPrimaryBarMinHeightRatio = 0.04
        static let onPrimaryBarOpacity = 0.9
        static let onPrimaryZeroBarOpacity = 0.32
        static let sparklineLineWidth = 1.5
        static let areaTopOpacity = 0.75
        static let minYDomainCeiling = 1.0
    }
}

struct MetricChartReferenceLines: View {
    var body: some View {
        VStack(spacing: 0) {
            line(opacity: 0.2)
            Spacer(minLength: 0)
            line(opacity: 0.2)
            Spacer(minLength: 0)
            line(opacity: 0.6)
        }
    }

    private func line(opacity: Double) -> some View {
        Rectangle()
            .fill(Color.primary.opacity(opacity))
            .frame(height: 1)
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

#Preview("Bar on primary") {
    MetricChartView(data: sampleData(), style: .barOnPrimary)
        .frame(width: 200, height: 40)
        .padding()
        .background(Color(.brand))
}
#endif
