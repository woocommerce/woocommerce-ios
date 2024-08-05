import SwiftUI
import enum Yosemite.StatsTimeRangeV4
import struct Yosemite.DashboardCard

/// View for store performance on Dashboard screen
///
struct StorePerformanceView: View {
    @ObservedObject private var viewModel: StorePerformanceViewModel
    @State private var showingCustomRangePicker = false

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
        }
    }

    var statsView: some View {
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

                Text(Localization.revenue)
                    .if(!viewModel.hasRevenue) { $0.foregroundStyle(Color(.textSubtle)) }
                    .font(Font(StyleManager.statsTitleFont))
            }

            HStack(alignment: .bottom) {
                Group {
                    statsItemView(title: Localization.orders,
                                  value: viewModel.orderStatsText,
                                  redactMode: .none)
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
                .renderedIf(viewModel.hasRevenue)

                Text(Localization.noRevenueText)
                    .subheadlineStyle()
                    .frame(maxWidth: .infinity)
                    .renderedIf(!viewModel.hasRevenue)
            }
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
        if let chartViewModel = viewModel.chartViewModel {
            VStack {
                StoreStatsChart(viewModel: chartViewModel) { selectedIndex in
                    viewModel.trackInteraction()
                    viewModel.didSelectStatsInterval(at: selectedIndex)
                }
                .frame(height: Layout.chartViewHeight)

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
        static let revenue = NSLocalizedString(
            "storePerformanceView.revenue",
            value: "Revenue",
            comment: "Revenue stat label on dashboard."
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
    }
}

#Preview {
    StorePerformanceView(viewModel: StorePerformanceViewModel(siteID: 123,
                                                              usageTracksEventEmitter: .init()),
                         onCustomRangeRedactedViewTap: {},
                         onViewAllAnalytics: { _, _, _ in })
}
