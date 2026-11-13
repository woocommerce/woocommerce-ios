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
                if viewModel.analyticsEnabled {
                    StoreDashboardRangedCardContent(cardType: .performance,
                                                    hasError: viewModel.loadingError != nil,
                                                    reload: { await viewModel.reloadDataIfNeeded(forceRefresh: true) }) {
                        dateRangeHeader
                    } content: {
                        performanceContent
                    }
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

    var dateRangeHeader: some View {
        StoreDashboardDateRangeHeader(
            timeRange: viewModel.timeRange,
            dateText: displayedDateText,
            customTitle: Localization.custom,
            isDisabled: viewModel.syncingData,
            accessibilityPrefix: "performance",
            onSelect: selectTimeRange,
            onEditCustom: editCustomRange
        )
        .padding(.horizontal, StorePadding.p5)
        .redacted(reason: viewModel.showRedactedState ? .placeholder : [])
        .shimmering(active: viewModel.showRedactedState)
    }

    var performanceContent: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s0) {
            revenueTypeSelector
                .padding(.horizontal, StorePadding.p5)
                .padding(.top, StorePadding.p4)
                .padding(.bottom, StorePadding.p2)
            stats
            StoreDashboardTimestamp(
                text: timestampText,
                showsInfoButton: viewModel.shouldShowAnalyticsImportUpdateModeInfoButton,
                infoAccessibilityLabel: Localization.scheduledUpdatesInfoAccessibilityLabel,
                onInfoTapped: showAnalyticsImportUpdateModeInfo
            )
            .padding(.top, StorePadding.p5)
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

    var revenueTypeSelector: some View {
        StoreSegmentedControl(
            selection: Binding(get: { viewModel.revenueType }, set: { viewModel.didSelectRevenueType($0) }),
            options: DashboardRevenueStatsType.allCases,
            title: revenueTypeTitle
        )
        .disabled(viewModel.syncingData)
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
            if withIcon {
                switch viewModel.siteVisitStatMode {
                case .redactedDueToJetpack:
                    Image(uiImage: .jetpackLogoImage)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: StoreSpacing.s5, height: StoreSpacing.s5)
                        .foregroundStyle(Color(.jetpackGreen))
                        .offset(x: StoreSpacing.s5)
                case .redactedDueToCustomRange:
                    StoreIcon.CircleInfo.regular.image(size: .extraSmall)
                        .foregroundStyle(.storePrimary)
                        .offset(x: StoreSpacing.s5)
                case .default, .hidden:
                    EmptyView()
                }
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

    var statsValueColor: Color {
        if !viewModel.hasRevenue { return statsTextColor }
        return viewModel.shouldHighlightStats ? Color(.statsHighlighted) : statsTextColor
    }

    var statsTextColor: Color {
        .storeOnSurfaceVariant
    }

    var secondaryStatsTextColor: Color {
        colorScheme == .dark ? .storePaletteGray20 : .storePaletteGray60
    }

    var displayedDateText: String {
        viewModel.selectedDateText ?? viewModel.timeRangeText
    }

    var timestampText: String {
        viewModel.shouldShowScheduledAnalyticsImportInfo ?
        Localization.scheduledUpdatesDelayText :
        Localization.lastUpdatedText(time: viewModel.lastUpdatedTimestamp)
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

    func revenueTypeTitle(_ type: DashboardRevenueStatsType) -> String {
        switch type {
        case .total: Localization.revenueTypeTotal
        case .gross: Localization.revenueTypeGross
        case .net: Localization.revenueTypeNet
        }
    }
}

private extension StorePerformanceDashboardCard {
    typealias Localization = StorePerformanceView.Localization

    enum RedactMode { case none, withIcon, withoutIcon }

    enum Constants {
        static let chartHeight: CGFloat = 176
        static let chartContainerHeight = chartHeight + StorePadding.p4 * 2
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
