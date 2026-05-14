import Charts
import SwiftUI

/// Compact trailing chart for `MetricCellView`. Two render styles:
/// - `.sparkline` — thin line with a fading area fill (iOS Stocks app style).
/// - `.bar` — one bar per interval. Reserved for the wider main-metric row.
///
/// Color is driven by `tone` (up/down/neutral) and the active `\.storeWidgetTheme` from the
/// environment. The `.default` theme uses the brand-purple-friendly pastels declared in
/// `Palette`; `.sameAsSystem` falls through to the matching `systemGreen` / `systemRed` /
/// `systemGray` semantic colors so the chart adapts to light/dark mode.
///
/// Caller sizes via `.frame(...)` and gates on `count > 1`.
///
struct MetricChartView: View {
    @Environment(\.storeWidgetTheme) private var theme

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
            let layout = barLayout(chartWidth: proxy.size.width)
            configuredChart(layout: layout)
        }
    }

    @ViewBuilder
    private func configuredChart(layout: BarLayout) -> some View {
        let chart = Chart {
            // Baseline rule is emitted before the bars so the bars paint on top of it.
            if style == .bar, layout.showsBaseline {
                RuleMark(y: .value("Baseline", 0))
                    .foregroundStyle(theme.chartBaselineColor)
                    .lineStyle(StrokeStyle(
                        lineWidth: Constants.baselineLineWidth,
                        lineCap: .round,
                        dash: Constants.baselineDashPattern
                    ))
            }
            ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                switch style {
                case .bar:
                    barMark(index: index, point: point, barWidth: layout.barWidth)
                case .sparkline:
                    sparklineMarks(index: index, point: point)
                }
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: 0...yDomainMax)
        .chartPlotStyle { plot in
            plot.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityHidden(true)

        // chartXScale only applies to the bar style. For sparklines, the implicit
        // data-fit domain keeps the line/area spanning the full chart width.
        if style == .bar {
            chart.chartXScale(domain: layout.domain)
        } else {
            chart
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
    /// Corner radius is half the rendered bar width so tops are fully rounded.
    /// `barWidth` is fixed in points (capped to `maxBarSlotWidth * barWidthRatio`) so the
    /// bars don't balloon on sparse data; the surrounding chart x-domain is expanded
    /// in `barLayout` to center the bar group within the full chart width.
    ///
    func barMark(index: Int, point: MetricChartPoint, barWidth: Double) -> some ChartContent {
        let isZero = point.value <= 0
        return BarMark(
            x: .value("Index", Double(index)),
            y: .value("Value", max(point.value, barMinHeight)),
            width: .fixed(barWidth)
        )
        .foregroundStyle(isZero ? AnyShapeStyle(zeroBarColor) : AnyShapeStyle(lineGradient))
        .cornerRadius(min(barWidth / 2, Constants.maxBarCornerRadius))
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
        yDomainMax * Constants.barMinHeightRatio
    }

    /// Derived bar geometry for the `.bar` style.
    ///
    /// `barWidth` is `min(naturalSlot, maxBarSlotWidth) * barWidthRatio` — capped so wide
    /// widgets with few data points don't render chunky bars.
    ///
    /// `domain` is the x-scale domain to apply to the chart. When the cap isn't engaged
    /// it matches the natural categorical-equivalent domain (`-0.5...count - 0.5`) so the
    /// bars fill edge-to-edge. When the cap kicks in, the domain is widened symmetrically
    /// so the bars cluster in the chart's middle while the chart view itself still occupies
    /// the full width.
    ///
    /// Axis-hidden charts have negligible plot insets, so the chart's outer width is close
    /// enough to the plot width for this math.
    ///
    func barLayout(chartWidth: Double) -> BarLayout {
        let count = Double(data.count)
        guard count > 0, chartWidth > 0 else {
            return BarLayout(barWidth: 0, domain: -0.5...0.5, showsBaseline: false)
        }
        let naturalSlot = chartWidth / count
        let slot = min(naturalSlot, Constants.maxBarSlotWidth)
        let barWidth = slot * Constants.barWidthRatio
        let domainSpan = chartWidth / slot
        let halfEmpty = max(0, (domainSpan - count) / 2)
        return BarLayout(
            barWidth: barWidth,
            domain: (-0.5 - halfEmpty)...(count - 0.5 + halfEmpty),
            showsBaseline: halfEmpty > 0
        )
    }

    struct BarLayout {
        let barWidth: Double
        let domain: ClosedRange<Double>
        // True when the bar group is narrower than the chart and clusters in the middle.
        // The caller anchors the chart visually by drawing a baseline rule across the full width.
        let showsBaseline: Bool
    }

    /// Active tone palette stops `(high, low, deep)` — switches on the widget theme so the
    /// chart matches its background. `default` uses the brand-purple-friendly pastels;
    /// `sameAsSystem` uses semantic system colors that adapt to light/dark mode.
    var tonePalette: (high: Color, low: Color, deep: Color) {
        switch (theme, tone) {
        case (.default, .up):
            return (Palette.upHigh, Palette.upLow, Palette.upDeep)
        case (.default, .down):
            return (Palette.downHigh, Palette.downLow, Palette.downDeep)
        case (.default, .neutral):
            return (Palette.neutralHigh, Palette.neutralLow, Palette.neutralDeep)
        case (.sameAsSystem, .up):
            return (Color(.systemGreen), Color(.systemGreen).opacity(0.65), Color(.systemGreen).opacity(0.45))
        case (.sameAsSystem, .down):
            return (Color(.systemRed), Color(.systemRed).opacity(0.65), Color(.systemRed).opacity(0.45))
        case (.sameAsSystem, .neutral):
            return (Color(.systemGray), Color(.systemGray).opacity(0.65), Color(.systemGray).opacity(0.45))
        }
    }

    /// Solid color for zero-value bars — uses the deepest shade of the tone palette
    /// so the dot reads as darker than the dark end of the regular bar gradient.
    var zeroBarColor: Color {
        tonePalette.deep
    }

    /// Gradient applied to the bar fill / sparkline stroke. Lighter at the top, darker at
    /// the base — matches the iOS Stocks reading direction (peaks read brighter).
    var lineGradient: LinearGradient {
        LinearGradient(
            colors: [tonePalette.high, tonePalette.low],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Gradient applied to the sparkline `AreaMark`. Solid-ish at the top fading to fully
    /// transparent at the base, so the fill reads as a soft glow under the line.
    var areaGradient: LinearGradient {
        let top = tonePalette.high
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
    /// Palette stops for the `.default` (brand-purple) theme — tweak here to retune the
    /// brand-themed gradients applied by both the `.bar` and `.sparkline` styles.
    /// `.sameAsSystem` doesn't read this palette; it uses semantic system colors instead.
    /// `*Deep` shades are reserved for zero-value bars and sit a step darker than the
    /// dark end of each gradient.
    enum Palette {
        // Uptrend: pastel mint → soft sage. Same green semantics as the original, with luminance raised and
        // saturation dropped so the bars read as a highlight on purple rather than competing with it.
        static let upHigh = Color(red: 0.75, green: 0.95, blue: 0.82)
        static let upLow = Color(red: 0.45, green: 0.78, blue: 0.60)
        static let upDeep = Color(red: 0.32, green: 0.62, blue: 0.48)

        // Downtrend: pastel rose → mauve. Same red semantics, calmed to match the uptrend's chroma band.
        static let downHigh = Color(red: 1.00, green: 0.78, blue: 0.78)
        static let downLow = Color(red: 0.80, green: 0.50, blue: 0.55)
        static let downDeep = Color(red: 0.65, green: 0.38, blue: 0.42)

        // Neutral fallback when trend direction is unknown.
        static let neutralHigh = Color(red: 0.45, green: 0.95, blue: 0.78)
        static let neutralLow = Color(red: 0.55, green: 0.65, blue: 1.00)
        static let neutralDeep = Color(red: 0.40, green: 0.48, blue: 0.75)
    }

    enum Constants {
        static let barWidthRatio = 0.87
        // Per-bar slot cap in points. Bars never get wider than `maxBarSlotWidth * barWidthRatio`;
        // sparser data clusters the bars in the middle of the chart instead of stretching them.
        static let maxBarSlotWidth = 24.0
        static let barMinHeightRatio = 0.02
        static let sparklineLineWidth = 1.5
        static let baselineLineWidth = 1.0
        static let baselineDashPattern: [CGFloat] = [8, 5]
        static let maxBarCornerRadius = 6.0
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
