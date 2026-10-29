import StoreDesignSystem
import SwiftUI
import enum Yosemite.DashboardRevenueStatsType
import enum Yosemite.StatsTimeRangeV4
import struct Yosemite.DashboardCard

struct StorePerformanceDashboardCard: View {
    @ObservedObject private var viewModel: StorePerformanceViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingCustomRangePicker = false
    @State private var showingOrderTypePicker = false

    private let onCustomRangeRedactedViewTap: () -> Void
    private let onViewAllAnalytics: (Int64, TimeZone, StatsTimeRangeV4) -> Void
    private let onAnalyticsImportUpdateModeInfoTapped: () -> Void

    init(viewModel: StorePerformanceViewModel,
         onCustomRangeRedactedViewTap: @escaping () -> Void,
         onViewAllAnalytics: @escaping (Int64, TimeZone, StatsTimeRangeV4) -> Void,
         onAnalyticsImportUpdateModeInfoTapped: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onCustomRangeRedactedViewTap = onCustomRangeRedactedViewTap
        self.onViewAllAnalytics = onViewAllAnalytics
        self.onAnalyticsImportUpdateModeInfoTapped = onAnalyticsImportUpdateModeInfoTapped
    }

    var body: some View {
        StoreDashboardCardSurface {
            VStack(alignment: .leading, spacing: StoreSpacing.s0) {
                header
                if viewModel.loadingError != nil {
                    errorState
                } else if viewModel.analyticsEnabled {
                    performanceContent
                } else {
                    StoreDashboardUnavailableAnalyticsView(title: Localization.unavailableAnalytics)
                }
            }
        }
        .sheet(isPresented: $showingCustomRangePicker) {
            RangedDatePicker(startDate: viewModel.startDateForCustomRange,
                             endDate: viewModel.endDateForCustomRange,
                             customApplyButtonTitle: viewModel.buttonTitleForCustomRange) { start, end in
                viewModel.trackCustomRangeEvent(.DashboardCustomRange.customRangeConfirmed(isEditing: viewModel.timeRange.isCustomTimeRange))
                viewModel.didSelectTimeRange(.custom(from: start, to: end))
            }
        }
        .storeSheet(isPresented: $showingOrderTypePicker, sizing: .fitContent) {
            StorePerformanceOrderTypeSheet(viewModel: viewModel)
        }
        .onAppear(perform: viewModel.onViewAppear)
    }
}

private extension StorePerformanceDashboardCard {
    var header: some View {
        StoreDashboardCardHeader(DashboardCard.CardType.performance.name,
                                 showsError: !viewModel.analyticsEnabled || viewModel.loadingError != nil) {
            StoreDashboardCardOverflowMenu(isDisabled: viewModel.syncingData) {
                Button(Localization.hideCard, action: viewModel.hideStorePerformance)
            }
        }
    }

    var performanceContent: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s0) {
            dateRangeHeader
                .padding(.leading, StorePadding.p5)
            StoreDivider()
            revenueTypeSelector
                .padding(.horizontal, StorePadding.p5)
                .padding(.top, StorePadding.p4)
                .padding(.bottom, StorePadding.p2)
            stats
            timestamp
                .renderedIf(viewModel.lastUpdatedTimestamp.isNotEmpty)
            chart
            StoreDashboardCardFooterAction(Localization.viewAll, isDisabled: viewModel.syncingData) {
                viewModel.trackInteraction()
                onViewAllAnalytics(viewModel.siteID, viewModel.siteTimezone, viewModel.timeRange)
            }
            .redacted(reason: viewModel.syncingData ? .placeholder : [])
            .shimmering(active: viewModel.syncingData)
        }
        .redacted(reason: viewModel.showRedactedState ? .placeholder : [])
        .shimmering(active: viewModel.showRedactedState)
    }

    var dateRangeHeader: some View {
        HStack(spacing: StoreSpacing.s3) {
            Text(viewModel.timeRange.isCustomTimeRange ? Localization.custom : viewModel.timeRange.tabTitle)
                .storeTextStyle(.bodyMedium)
                .foregroundStyle(.storeOnSurface)
                .accessibilityIdentifier("performance-\(viewModel.timeRange.menuAccessibilityIdentifier)")

            dateRangeValue
                .padding(StorePadding.p3)

            Spacer(minLength: StoreSpacing.s0)
            dateRangeMenu
        }
    }

    @ViewBuilder var dateRangeValue: some View {
        if viewModel.timeRange.isCustomTimeRange {
            Button(action: editCustomRange) {
                HStack(spacing: StoreSpacing.s3) {
                    Text(displayedDateText).storeTextStyle(.bodyMedium)
                    StoreIcon.Pen.regular.image(size: .large).accessibilityHidden(true)
                }
                .foregroundStyle(.storeOnSecondaryContainer)
            }
            .buttonStyle(.plain)
        } else {
            Text(displayedDateText)
                .storeTextStyle(.bodyMedium)
                .foregroundStyle(.storeOnSurface)
        }
    }

    var dateRangeMenu: some View {
        Menu {
            ForEach(Constants.timeRanges, id: \.rawValue) { range in
                Button { selectTimeRange(range) } label: {
                    HStack {
                        Text(range.tabTitle)
                        if rangeMatchesSelection(range) {
                            StoreIcon.Check.solid.image(size: .small)
                        }
                    }
                }
                .accessibilityIdentifier(range.menuAccessibilityIdentifier)
            }
        } label: {
            StoreIcon.CalendarDays.regular.image(size: .largeIncreased)
                .foregroundStyle(.storeOnSurface)
                .frame(minWidth: StoreSize.minimumTapTarget, minHeight: StoreSize.minimumTapTarget)
                .contentShape(.rect)
        }
        .disabled(viewModel.syncingData)
        .accessibilityIdentifier("performance-time-range-menu")
        .accessibilityLabel(Localization.dateRange)
    }

    var revenueTypeSelector: some View {
        StoreSegmentedControl(
            selection: Binding(get: { viewModel.revenueType }, set: viewModel.didSelectRevenueType),
            options: DashboardRevenueStatsType.allCases,
            title: revenueTypeTitle
        )
        .disabled(viewModel.syncingData)
        .accessibilityIdentifier("performance-revenue-type-picker")
        .accessibilityLabel(Localization.revenueTypeAccessibilityLabel)
    }

    var stats: some View {
        VStack(spacing: StoreSpacing.s5) {
            if viewModel.hasRevenue {
                Text(viewModel.revenueStatsText)
                    .storeTextStyle(.headlineLarge)
                    .foregroundStyle(statsValueColor)
                    .accessibilityIdentifier("revenue-value")
            }
            statItems
        }
        .foregroundStyle(.storeOnSurface)
        .padding(.top, StorePadding.p5)
    }

    var statItems: some View {
        HStack(alignment: .bottom, spacing: StoreSpacing.s0) {
            ordersStat.frame(maxWidth: .infinity)
            statItem(Localization.visitors, value: viewModel.visitorStatsText, redactMode: .withIcon).frame(maxWidth: .infinity)
            statItem(Localization.conversion, value: viewModel.conversionStatsText, redactMode: .withoutIcon).frame(maxWidth: .infinity)
        }
    }

    var ordersStat: some View {
        VStack(spacing: StoreSpacing.s0) {
            Text(viewModel.orderStatsText)
                .storeTextStyle(.titleLarge.emphasized)
                .foregroundStyle(statsValueColor)
            Button {
                viewModel.trackInteraction()
                viewModel.trackOrderDateTypeSelectorTapped()
                showingOrderTypePicker = true
            } label: {
                HStack(spacing: StoreSpacing.s0) {
                    Text(viewModel.orderType.localizedTitle)
                        .storeTextStyle(.bodySmall)
                        .multilineTextAlignment(.center)
                    StoreIcon.AngleDown.regular.image(size: .medium).accessibilityHidden(true)
                }
                .foregroundStyle(statsTextColor)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.syncingData || viewModel.updatingOrderType != nil)
            .accessibilityIdentifier("performance-order-type-button")
            .accessibilityHint(Localization.orderTypeAccessibilityHint)
        }
    }

    func statItem(_ title: String, value: String, redactMode: RedactMode) -> some View {
        VStack(spacing: StoreSpacing.s0) {
            if redactMode == .none || viewModel.siteVisitStatMode == .default {
                Text(value)
                    .storeTextStyle(.titleLarge.emphasized)
                    .foregroundStyle(statsValueColor)
            } else {
                redactedStat(withIcon: redactMode == .withIcon)
            }
            Text(title)
                .storeTextStyle(.bodySmall)
                .foregroundStyle(statsTextColor)
        }
        .contentShape(.rect)
        .onTapGesture {
            guard redactMode != .none,
                  !viewModel.syncingData,
                  viewModel.unavailableVisitStatsDueToCustomRange,
                  viewModel.siteVisitStatMode == .redactedDueToCustomRange else { return }
            viewModel.trackInteraction()
            onCustomRangeRedactedViewTap()
        }
    }

    func redactedStat(withIcon: Bool) -> some View {
        VStack(alignment: .trailing, spacing: StoreSpacing.s0) {
            if withIcon, viewModel.redactedViewIcon != nil {
                StoreIcon.CircleInfo.regular.image(size: .extraSmall)
                    .foregroundStyle(.storePrimary)
                    .offset(x: StoreSpacing.s5)
            }
            Color.storeStateLayerOnSurfaceOpacity16
                .frame(width: StoreSpacing.s8, height: StoreSpacing.s4)
                .clipShape(.rect(cornerRadius: StoreRadius.extraSmall))
        }
    }

    var emptyStats: some View {
        Text(Localization.noRevenueText)
            .storeTextStyle(.bodyMedium)
            .foregroundStyle(.storeOnSurfaceVariant)
            .frame(maxWidth: .infinity, minHeight: Constants.chartContainerHeight)
    }

    var timestamp: some View {
        Group {
            if viewModel.shouldShowAnalyticsImportUpdateModeInfoButton {
                Button(action: showAnalyticsImportUpdateModeInfo) {
                    timestampContent
                }
                .buttonStyle(.plain)
                .accessibilityLabel(timestampText)
                .accessibilityHint(Localization.scheduledUpdatesInfoAccessibilityLabel)
            } else {
                timestampContent
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, StorePadding.p5)
    }

    var timestampContent: some View {
        HStack(spacing: StoreSpacing.s2) {
            Text(timestampText)
                .storeTextStyle(.bodyMedium)
                .foregroundStyle(secondaryStatsTextColor)
            if viewModel.shouldShowAnalyticsImportUpdateModeInfoButton {
                StoreIcon.CircleInfo.regular.image(size: .small)
                    .foregroundStyle(.storePrimary)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: StoreSize.minimumTapTarget)
        .contentShape(Rectangle())
    }

    var timestampText: String {
        viewModel.shouldShowScheduledAnalyticsImportInfo ?
        Localization.scheduledUpdatesDelayText :
        Localization.lastUpdatedText(time: viewModel.lastUpdatedTimestamp)
    }

    func showAnalyticsImportUpdateModeInfo() {
        viewModel.trackAnalyticsImportUpdateModeInfoTapped()
        onAnalyticsImportUpdateModeInfoTapped()
    }

    @ViewBuilder var chart: some View {
        if let chartViewModel = viewModel.chartViewModel, chartViewModel.hasRevenue {
            VStack(spacing: StoreSpacing.s0) {
                StoreStatsChart(viewModel: chartViewModel,
                                resetSignal: viewModel.chartSelectionResetPublisher,
                                onIntervalSelected: viewModel.didSelectStatsInterval)
                    .frame(height: Constants.chartHeight)
                    .padding(.horizontal, StorePadding.p5)
                    .padding(.vertical, StorePadding.p4)
                    .accessibilityIdentifier("store-stats-chart")
                if viewModel.hasRevenue, let granularityText = viewModel.granularityText {
                    Text(granularityText)
                        .storeTextStyle(.bodyMedium)
                        .foregroundStyle(secondaryStatsTextColor)
                        .frame(maxWidth: .infinity)
                }
            }
        } else if !viewModel.hasRevenue {
            emptyStats
        }
    }

    var errorState: some View {
        StoreDashboardCardErrorView {
            ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .performance))
            Task { await viewModel.reloadDataIfNeeded(forceRefresh: true) }
        }
    }

    var statsValueColor: Color {
        if !viewModel.hasRevenue { return statsTextColor }
        return viewModel.shouldHighlightStats ? Color(.statsHighlighted) : statsTextColor
    }

    var statsTextColor: Color {
        colorScheme == .dark ? .storePaletteGray10 : .storePaletteGray80
    }

    var secondaryStatsTextColor: Color {
        colorScheme == .dark ? .storePaletteGray20 : .storePaletteGray60
    }

    var displayedDateText: String {
        viewModel.selectedDateText ?? viewModel.timeRangeText
    }

    func editCustomRange() {
        viewModel.trackInteraction()
        viewModel.trackCustomRangeEvent(.DashboardCustomRange.editButtonTapped())
        showingCustomRangePicker = true
    }

    func selectTimeRange(_ range: StatsTimeRangeV4) {
        viewModel.trackInteraction()
        if range.isCustomTimeRange {
            showingCustomRangePicker = true
            viewModel.trackCustomRangeEvent(viewModel.timeRange.isCustomTimeRange ?
                                            .DashboardCustomRange.editButtonTapped() :
                                            .DashboardCustomRange.addButtonTapped())
        } else {
            viewModel.didSelectTimeRange(range)
        }
    }

    func rangeMatchesSelection(_ range: StatsTimeRangeV4) -> Bool {
        range.isCustomTimeRange && viewModel.timeRange.isCustomTimeRange || range == viewModel.timeRange
    }

    func revenueTypeTitle(_ type: DashboardRevenueStatsType) -> String {
        switch type {
        case .total: Localization.revenueTypeTotal
        case .gross: Localization.revenueTypeGross
        case .net: Localization.revenueTypeNet
        }
    }
}

private extension StorePerformanceDashboardCard {
    enum RedactMode { case none, withIcon, withoutIcon }

    enum Constants {
        static let timeRanges: [StatsTimeRangeV4] = [.today, .thisWeek, .thisMonth, .thisYear, .custom(from: .now, to: .now)]
        static let chartHeight: CGFloat = 176
        static let chartContainerHeight = chartHeight + StorePadding.p4 * 2
    }

    enum Localization {
        static let hideCard = NSLocalizedString("storePerformanceView.hideCard", value: "Hide Performance", comment: "Menu item to dismiss Performance")
        static let custom = NSLocalizedString("storePerformanceView.custom", value: "Custom", comment: "Title of the custom time range")
        static let noRevenueText = NSLocalizedString(
            "storePerformanceView.noRevenueText",
            value: "No revenue for selected dates",
            comment: "Text on the store stats chart when there is no revenue"
        )
        static let visitors = NSLocalizedString("storePerformanceView.visitors", value: "Visitors", comment: "Visitors stat label")
        static let conversion = NSLocalizedString("storePerformanceView.conversion", value: "Conversion", comment: "Conversion stat label")
        static let viewAll = NSLocalizedString("storePerformanceView.viewAll", value: "View all store analytics", comment: "Button to Analytics Hub")
        static let dateRange = NSLocalizedString("Date Range", comment: "Title of the range selection list")
        static let orderTypeAccessibilityHint = NSLocalizedString(
            "storePerformanceView.orderTypeAccessibilityHint",
            value: "Opens a bottom sheet to change which orders are included in your performance totals.",
            comment: "Accessibility hint for the order type button"
        )
        static let scheduledUpdatesDelayText = NSLocalizedString(
            "storePerformanceView.scheduledUpdatesDelayText",
            value: "Stats may be up to 12 hours delayed",
            comment: "Text shown when analytics updates are scheduled"
        )
        static let unavailableAnalytics = NSLocalizedString(
            "storePerformanceView.unavailableAnalyticsView.title",
            value: "Unable to display your store's performance",
            comment: "Title when Analytics is unavailable"
        )
        static let revenueTypeTotal = NSLocalizedString("storePerformanceView.revenueType.total", value: "Total", comment: "Total revenue option")
        static let revenueTypeGross = NSLocalizedString("storePerformanceView.revenueType.gross", value: "Gross", comment: "Gross revenue option")
        static let revenueTypeNet = NSLocalizedString("storePerformanceView.revenueType.net", value: "Net", comment: "Net revenue option")
        static let revenueTypeAccessibilityLabel = NSLocalizedString(
            "storePerformanceView.revenueType.accessibilityLabel",
            value: "Revenue type",
            comment: "Accessibility label for the revenue selector"
        )
        static let scheduledUpdatesInfoAccessibilityLabel = NSLocalizedString(
            "storePerformanceView.scheduledUpdatesInfoAccessibilityLabel",
            value: "Analytics update details",
            comment: "Accessibility label for analytics update details"
        )

        static func lastUpdatedText(time: String) -> String {
            let format = NSLocalizedString("Last Updated: %@", comment: "Time when the performance card was last updated")
            return String.localizedStringWithFormat(format, time)
        }
    }
}

#Preview {
    StorePerformanceDashboardCard(
        viewModel: StorePerformanceViewModel(siteID: 123, usageTracksEventEmitter: .init()),
        onCustomRangeRedactedViewTap: {},
        onViewAllAnalytics: { _, _, _ in },
        onAnalyticsImportUpdateModeInfoTapped: {}
    )
    .padding(StorePadding.p7)
    .background(Color.storeSectionBackground)
}
