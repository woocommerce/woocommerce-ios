import SwiftUI
import enum Yosemite.StatsTimeRangeV4
import enum Yosemite.DashboardRevenueStatsType
import struct Yosemite.DashboardCard

/// View for store performance on Dashboard screen
///
struct StorePerformanceView: View {
    @ObservedObject private var viewModel: StorePerformanceViewModel
    @State private var showingCustomRangePicker = false
    @State private var showingOrderTypePicker = false

    private var statsValueColor: Color {
        guard viewModel.hasRevenue else {
            return Color(.textSubtle)
        }
        return Color(viewModel.shouldHighlightStats ? .statsHighlighted : .text)
    }

    private let onCustomRangeRedactedViewTap: () -> Void
    private let onViewAllAnalytics: (_ siteID: Int64,
                                     _ timeZone: TimeZone,
                                     _ timeRange: StatsTimeRangeV4) -> Void

    init(viewModel: StorePerformanceViewModel,
         onCustomRangeRedactedViewTap: @escaping () -> Void,
         onViewAllAnalytics: @escaping (Int64, TimeZone, StatsTimeRangeV4) -> Void) {
        self.viewModel = viewModel
        self.onCustomRangeRedactedViewTap = onCustomRangeRedactedViewTap
        self.onViewAllAnalytics = onViewAllAnalytics
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.padding) {
            header
                .padding(.horizontal, Layout.padding)

            if viewModel.loadingError != nil {
                errorStateView
                    .padding(.horizontal, Layout.padding)
            } else if viewModel.analyticsEnabled {
                timeRangeBar
                    .padding(.horizontal, Layout.padding)
                    .redacted(reason: viewModel.showRedactedState ? [.placeholder] : [])
                    .shimmering(active: viewModel.showRedactedState)

                Divider()

                revenueTypeSelector
                    .padding(.horizontal, Layout.padding)
                    .redacted(reason: viewModel.showRedactedState ? [.placeholder] : [])
                    .shimmering(active: viewModel.showRedactedState)

                statsView
                    .padding(.vertical, Layout.padding)
                    .redacted(reason: viewModel.showRedactedState ? [.placeholder] : [])
                    .shimmering(active: viewModel.showRedactedState)

                timestampView
                    .renderedIf(viewModel.lastUpdatedTimestamp.isNotEmpty)
                    .redacted(reason: viewModel.showRedactedState ? [.placeholder] : [])
                    .shimmering(active: viewModel.showRedactedState)

                chartView
                    .padding(.horizontal, Layout.padding)
                    .redacted(reason: viewModel.showRedactedState ? [.placeholder] : [])
                    .shimmering(active: viewModel.showRedactedState)

                Divider()
                    .padding(.leading, Layout.padding)

                viewAllAnalyticsButton
                    .padding(.horizontal, Layout.padding)
                    .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                    .shimmering(active: viewModel.syncingData)
            } else {
                UnavailableAnalyticsView(title: Localization.unavailableAnalytics)
                    .padding(.horizontal, Layout.padding)
            }
        }
        .padding(.vertical, Layout.padding)
        .background(Color(.listForeground(modal: false)))
        .clipShape(RoundedRectangle(cornerSize: Layout.cornerSize))
        .padding(.horizontal, Layout.padding)
        .sheet(isPresented: $showingCustomRangePicker) {
            RangedDatePicker(startDate: viewModel.startDateForCustomRange,
                             endDate: viewModel.endDateForCustomRange,
                             customApplyButtonTitle: viewModel.buttonTitleForCustomRange,
                             datesSelected: { start, end in
                viewModel.trackCustomRangeEvent(.DashboardCustomRange.customRangeConfirmed(isEditing: viewModel.timeRange.isCustomTimeRange))
                viewModel.didSelectTimeRange(.custom(from: start, to: end))
            })
        }
        .sheet(isPresented: $showingOrderTypePicker) {
            PerformanceCardOrderTypeBottomSheet(viewModel: viewModel)
        }
        .onAppear {
            viewModel.onViewAppear()
        }
    }
}

private extension StorePerformanceView {
    var header: some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(Color.secondary)
                .headlineStyle()
                .renderedIf(!viewModel.analyticsEnabled || viewModel.loadingError != nil)

            Text(DashboardCard.CardType.performance.name)
                .headlineStyle()
            Spacer()
            Menu {
                Button(Localization.hideCard) {
                    viewModel.hideStorePerformance()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(Color.secondary)
                    .padding(.leading, Layout.padding)
                    .padding(.vertical, Layout.hideIconVerticalPadding)
            }
            .disabled(viewModel.syncingData)
        }
    }

    var timeRangeBar: some View {
        HStack {
            AdaptiveStack(horizontalAlignment: .leading) {
                Text(viewModel.timeRange.isCustomTimeRange ?
                     Localization.custom : viewModel.timeRange.tabTitle)
                    .foregroundStyle(Color(.text))
                    .subheadlineStyle()
                if viewModel.timeRange.isCustomTimeRange {
                    Button {
                        viewModel.trackInteraction()
                        viewModel.trackCustomRangeEvent(.DashboardCustomRange.editButtonTapped())
                        showingCustomRangePicker = true
                    } label: {
                        HStack {
                            Text(viewModel.timeRangeText)
                            Image(systemName: "pencil")
                        }
                        .foregroundStyle(Color.accentColor)
                        .subheadlineStyle()
                    }
                } else {
                    Text(viewModel.timeRangeText)
                        .subheadlineStyle()
                }
            }
            Spacer()
            StatsTimeRangePicker(currentTimeRange: viewModel.timeRange) { newTimeRange in
                viewModel.trackInteraction()

                if newTimeRange.isCustomTimeRange {
                    showingCustomRangePicker = true
                    if viewModel.timeRange.isCustomTimeRange {
                        viewModel.trackCustomRangeEvent(.DashboardCustomRange.editButtonTapped())
                    } else {
                        viewModel.trackCustomRangeEvent(.DashboardCustomRange.addButtonTapped())
                    }
                } else {
                    viewModel.didSelectTimeRange(newTimeRange)
                }
            }
            .disabled(viewModel.syncingData)
            .accessibilityIdentifier("performance-time-range-menu")
        }
    }

    /// Segmented control above the stats view that lets the merchant pick which revenue metric
    /// (Total / Gross / Net) is displayed in the card total and the chart. Order mirrors Android.
    var revenueTypeSelector: some View {
        Picker(Localization.revenueTypeAccessibilityLabel,
               selection: Binding(
                get: { viewModel.revenueType },
                set: { viewModel.didSelectRevenueType($0) }
               )) {
            Text(Localization.revenueTypeTotal).tag(DashboardRevenueStatsType.total)
            Text(Localization.revenueTypeGross).tag(DashboardRevenueStatsType.gross)
            Text(Localization.revenueTypeNet).tag(DashboardRevenueStatsType.net)
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("performance-revenue-type-picker")
        .accessibilityLabel(Localization.revenueTypeAccessibilityLabel)
        .disabled(viewModel.syncingData)
    }

    @ViewBuilder
    var statsView: some View {
        if viewModel.hasRevenue {
            VStack(spacing: Layout.padding) {
                VStack(spacing: Layout.contentVerticalSpacing) {
                    if let selectedDateText = viewModel.selectedDateText {
                        Text(selectedDateText)
                            .font(Font(StyleManager.statsTitleFont))
                    }

                    Text(viewModel.revenueStatsText)
                        .fontWeight(.semibold)
                        .foregroundStyle(statsValueColor)
                        .largeTitleStyle()
                        .accessibilityIdentifier("revenue-value")
                }

                HStack(alignment: .bottom) {
                    Group {
                        ordersStatsItemView
                            .frame(maxWidth: .infinity)

                        statsItemView(title: Localization.visitors,
                                      value: viewModel.visitorStatsText,
                                      redactMode: .withIcon)
                        .frame(maxWidth: .infinity)

                        statsItemView(title: Localization.conversion,
                                      value: viewModel.conversionStatsText,
                                      redactMode: .withoutIcon)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        } else {
            emptyStatsView
        }
    }

    var emptyStatsView: some View {
        VStack(spacing: Layout.emptyViewSpacing) {
            Image(.magnifyingGlassNotFoundGrey)

            Text(Localization.noRevenueText)
                .subheadlineStyle()
                .frame(maxWidth: .infinity)
        }
    }

    var timestampView: some View {
        Text(Localization.lastUpdatedText(time: viewModel.lastUpdatedTimestamp))
            .footnoteStyle()
            .frame(maxWidth: .infinity, alignment: .center)
    }

    func statsItemView(title: String, value: String, redactMode: RedactMode) -> some View {
        VStack(spacing: Layout.contentVerticalSpacing) {
            if redactMode == .none || viewModel.siteVisitStatMode == .default {
                Text(value)
                    .font(Font(StyleManager.statsFont))
                    .foregroundStyle(statsValueColor)
            } else {
                statValueRedactedView(withIcon: redactMode == .withIcon)
            }
            Text(title)
                .font(Font(StyleManager.statsTitleFont))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard redactMode != .none,
                !viewModel.syncingData,
                viewModel.unavailableVisitStatsDueToCustomRange,
                viewModel.siteVisitStatMode == .redactedDueToCustomRange else {
                return
            }

            viewModel.trackInteraction()
            onCustomRangeRedactedViewTap()
        }
    }

    /// "Orders" stats column with the order date type selector affordance.
    /// Tapping the title or chevron opens the order type bottom sheet.
    var ordersStatsItemView: some View {
        VStack(spacing: Layout.contentVerticalSpacing) {
            Text(viewModel.orderStatsText)
                .font(Font(StyleManager.statsFont))
                .foregroundStyle(statsValueColor)
            Button {
                viewModel.trackInteraction()
                viewModel.trackOrderDateTypeSelectorTapped()
                showingOrderTypePicker = true
            } label: {
                HStack(alignment: .center, spacing: Layout.orderTypeChevronSpacing) {
                    Text(viewModel.orderType.localizedTitle)
                        .font(Font(StyleManager.statsTitleFont))
                        .lineLimit(2)
                        .minimumScaleFactor(Layout.orderTypeLabelMinScale)
                        .multilineTextAlignment(.center)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(Color(.textSubtle))
                }.padding(.leading)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("performance-order-type-button")
            .accessibilityHint(Localization.orderTypeAccessibilityHint)
            .disabled(viewModel.syncingData || viewModel.isUpdatingOrderType)
        }
        .contentShape(Rectangle())
    }

    func statValueRedactedView(withIcon: Bool) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Group {
                if let image = viewModel.redactedViewIcon, withIcon {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(Color(viewModel.redactedViewIconColor))
                } else {
                    EmptyView()
                }
            }
            .frame(width: Layout.redactedViewIconSize, height: Layout.redactedViewIconSize)
            .offset(Layout.redactedViewIconOffset)

            Color(.systemColor(.secondarySystemBackground))
                .frame(width: Layout.redactedViewWidth, height: Layout.redactedViewHeight)
                .clipShape(RoundedRectangle(cornerSize: Layout.redactedViewCornerSize))
        }
    }

    @ViewBuilder
    var chartView: some View {
        if let chartViewModel = viewModel.chartViewModel,
           chartViewModel.hasRevenue {
            VStack {
                StoreStatsChart(viewModel: chartViewModel) { selectedIndex in
                    viewModel.didSelectStatsInterval(at: selectedIndex)
                }
                .frame(height: Layout.chartViewHeight)
                .accessibilityIdentifier("store-stats-chart")

                if viewModel.hasRevenue,
                   let granularityText = viewModel.granularityText {
                    Text(granularityText)
                        .font(Font(StyleManager.statsTitleFont))
                }
            }
        }
    }

    var viewAllAnalyticsButton: some View {
        Button {
            viewModel.trackInteraction()
            onViewAllAnalytics(viewModel.siteID, viewModel.siteTimezone, viewModel.timeRange)
        } label: {
            HStack {
                Text(Localization.viewAll)
                Spacer()
                Image(systemName: "chevron.forward")
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .disabled(viewModel.syncingData)
    }

    var errorStateView: some View {
        DashboardCardErrorView(onRetry: {
            ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .performance))
            Task {
                await viewModel.reloadDataIfNeeded(forceRefresh: true)
            }
        })
    }
}

private extension StorePerformanceView {
    /// Redact modes for stat values.
    enum RedactMode {
        case none
        case withIcon
        case withoutIcon
    }

    enum Layout {
        static let padding: CGFloat = 16
        static let cornerSize = CGSize(width: 8.0, height: 8.0)
        static let strokeWidth: CGFloat = 0.5
        static let chartViewHeight: CGFloat = 176
        static let contentVerticalSpacing: CGFloat = 8
        static let redactedViewCornerSize = CGSize(width: 2.0, height: 2.0)
        static let redactedViewWidth: CGFloat = 32
        static let redactedViewHeight: CGFloat = 10
        static let redactedViewIconSize: CGFloat = 14
        static let redactedViewIconOffset = CGSize(width: 16, height: 0)
        static let hideIconVerticalPadding: CGFloat = 8
        static let emptyViewSpacing: CGFloat = 24
        static let orderTypeChevronSpacing: CGFloat = 4
        static let orderTypeLabelMinScale: CGFloat = 0.7
    }

    enum Localization {
        static let hideCard = NSLocalizedString(
            "storePerformanceView.hideCard",
            value: "Hide Performance",
            comment: "Menu item to dismiss the store performance section on the Dashboard screen"
        )
        static let custom = NSLocalizedString(
            "storePerformanceView.custom",
            value: "Custom",
            comment: "Title of the custom time range on the store performance card on the Dashboard screen"
        )
        static let noRevenueText = NSLocalizedString(
            "storePerformanceView.noRevenueText",
            value: "No revenue for selected dates",
            comment: "Text on the store stats chart on the Dashboard screen when there is no revenue"
        )
        static let orders = NSLocalizedString(
            "storePerformanceView.orders",
            value: "Orders",
            comment: "Orders stat label on dashboard - should be plural."
        )
        static let orderTypeAccessibilityHint = NSLocalizedString(
            "storePerformanceView.orderTypeAccessibilityHint",
            value: "Opens a bottom sheet to change which orders are included in your performance totals.",
            comment: "Accessibility hint for the order type chevron button on the dashboard Performance card."
        )
        static let visitors = NSLocalizedString(
            "storePerformanceView.visitors",
            value: "Visitors",
            comment: "Visitors stat label on dashboard - should be plural."
        )
        static let conversion = NSLocalizedString(
            "storePerformanceView.conversion",
            value: "Conversion",
            comment: "Conversion stat label on dashboard."
        )
        static let viewAll = NSLocalizedString(
            "storePerformanceView.viewAll",
            value: "View all store analytics",
            comment: "Button to navigate to Analytics Hub."
        )
        static func lastUpdatedText(time: String) -> String {
            let format = NSLocalizedString("Last Updated: %@", comment: "Time for when the performance card was last updated")
            return String.localizedStringWithFormat(format, time)
        }
        static let unavailableAnalytics = NSLocalizedString(
            "storePerformanceView.unavailableAnalyticsView.title",
            value: "Unable to display your store's performance",
            comment: "Title when the Performance card is disabled because the analytics feature is unavailable"
        )
        static let revenueTypeTotal = NSLocalizedString(
            "storePerformanceView.revenueType.total",
            value: "Total",
            comment: "Segmented control option that displays Total revenue (including taxes and shipping) on the Performance card. Matches Android."
        )
        static let revenueTypeGross = NSLocalizedString(
            "storePerformanceView.revenueType.gross",
            value: "Gross",
            comment: "Segmented control option that displays Gross sales (before taxes, shipping, refunds, discounts) on the Performance card. Matches Android."
        )
        static let revenueTypeNet = NSLocalizedString(
            "storePerformanceView.revenueType.net",
            value: "Net",
            comment: "Segmented control option that displays Net revenue (after refunds and discounts) on the Performance card. Matches Android."
        )
        static let revenueTypeAccessibilityLabel = NSLocalizedString(
            "storePerformanceView.revenueType.accessibilityLabel",
            value: "Revenue type",
            comment: "Accessibility label for the segmented control that switches between Gross, Net, and Total revenue on the Performance card."
        )
    }
}

#Preview {
    StorePerformanceView(viewModel: StorePerformanceViewModel(siteID: 123,
                                                              usageTracksEventEmitter: .init()),
                         onCustomRangeRedactedViewTap: {},
                         onViewAllAnalytics: { _, _, _ in })
}
