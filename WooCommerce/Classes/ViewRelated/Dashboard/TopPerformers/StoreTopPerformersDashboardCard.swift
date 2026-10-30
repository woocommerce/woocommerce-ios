import StoreDesignSystem
import SwiftUI
import enum Yosemite.StatsTimeRangeV4
import struct Yosemite.DashboardCard
import struct Yosemite.TopEarnerStatsItem

struct StoreTopPerformersDashboardCard: View {
    @ObservedObject private var viewModel: TopPerformersDashboardViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingCustomRangePicker = false

    private let onViewAllAnalytics: (Int64, TimeZone, StatsTimeRangeV4) -> Void
    private let onAnalyticsImportUpdateModeInfoTapped: () -> Void

    init(viewModel: TopPerformersDashboardViewModel,
         onViewAllAnalytics: @escaping (Int64, TimeZone, StatsTimeRangeV4) -> Void,
         onAnalyticsImportUpdateModeInfoTapped: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onViewAllAnalytics = onViewAllAnalytics
        self.onAnalyticsImportUpdateModeInfoTapped = onAnalyticsImportUpdateModeInfoTapped
    }

    var body: some View {
        StoreDashboardCardSurface {
            VStack(alignment: .leading, spacing: StoreSpacing.s0) {
                header
                if !viewModel.analyticsEnabled {
                    StoreDashboardUnavailableAnalyticsView(title: Localization.unavailableAnalytics)
                } else if viewModel.syncingError != nil {
                    errorState
                } else {
                    topPerformersContent
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
        .sheet(item: $viewModel.selectedItem) { item in
            ViewControllerContainer(productDetailView(for: item))
        }
        .onAppear(perform: viewModel.onViewAppear)
    }
}

private extension StoreTopPerformersDashboardCard {
    var header: some View {
        StoreDashboardCardHeader(DashboardCard.CardType.topPerformers.name,
                                 showsError: !viewModel.analyticsEnabled || viewModel.syncingError != nil) {
            StoreDashboardCardOverflowMenu(isDisabled: viewModel.syncingData) {
                Button(Localization.hideCard, action: viewModel.dismissTopPerformers)
            }
        }
    }

    var topPerformersContent: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s0) {
            dateRangeHeader
                .padding(.horizontal, StorePadding.p5)
                .redacted(reason: viewModel.periodViewModel.redacted.header ? .placeholder : [])
                .shimmering(active: viewModel.periodViewModel.redacted.header)
            StoreDivider()
                .padding(.bottom, StorePadding.p5)
            StoreTopPerformersPeriodView(viewModel: viewModel.periodViewModel)
            timestamp
                .renderedIf(viewModel.lastUpdatedTimestamp.isNotEmpty)
            StoreDashboardCardFooterAction(Localization.viewAll, isDisabled: viewModel.syncingData) {
                viewModel.trackInteraction()
                onViewAllAnalytics(viewModel.siteID, viewModel.siteTimezone, viewModel.timeRange)
            }
            .redacted(reason: viewModel.periodViewModel.redacted.actionButton ? .placeholder : [])
            .shimmering(active: viewModel.periodViewModel.redacted.actionButton)
        }
    }

    var dateRangeHeader: some View {
        HStack(spacing: StoreSpacing.s3) {
            Text(viewModel.timeRange.isCustomTimeRange ? Localization.custom : viewModel.timeRange.tabTitle)
                .storeTextStyle(.bodyMedium)
                .foregroundStyle(.storeOnSurface)
                .accessibilityIdentifier("top-performers-\(viewModel.timeRange.menuAccessibilityIdentifier)")

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
                    Text(viewModel.timeRangeText)
                        .storeTextStyle(.bodyMedium)
                    StoreIcon.Pen.regular.image(size: .large)
                        .accessibilityHidden(true)
                }
                .foregroundStyle(.storeOnSecondaryContainer)
            }
            .buttonStyle(.plain)
        } else {
            Text(viewModel.timeRangeText)
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
                .frame(minWidth: StoreSize.minimumTapTarget,
                       minHeight: StoreSize.minimumTapTarget,
                       alignment: .trailing)
                .contentShape(.rect)
        }
        .disabled(viewModel.syncingData)
        .accessibilityIdentifier("top-performers-time-range-menu")
        .accessibilityLabel(Localization.dateRange)
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
        .padding(StorePadding.p5)
        .redacted(reason: viewModel.periodViewModel.redacted.rows ? .placeholder : [])
        .shimmering(active: viewModel.periodViewModel.redacted.rows)
    }

    var timestampContent: some View {
        HStack(spacing: StoreSpacing.s2) {
            Text(timestampText)
                .storeTextStyle(.bodyMedium)
                .foregroundStyle(secondaryTextColor)
                .multilineTextAlignment(.center)
            if viewModel.shouldShowAnalyticsImportUpdateModeInfoButton {
                StoreIcon.CircleInfo.regular.image(size: .small)
                    .foregroundStyle(.storePrimary)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: StoreSize.minimumTapTarget)
        .contentShape(.rect)
    }

    var timestampText: String {
        viewModel.shouldShowScheduledAnalyticsImportInfo ?
        Localization.scheduledUpdatesDelayText :
        Localization.lastUpdatedText(time: viewModel.lastUpdatedTimestamp)
    }

    var secondaryTextColor: Color {
        colorScheme == .dark ? .storePaletteGray20 : .storePaletteGray60
    }

    var errorState: some View {
        StoreDashboardCardErrorView {
            ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .topPerformers))
            Task { await viewModel.reloadDataIfNeeded(forceRefresh: true) }
        }
    }

    func showAnalyticsImportUpdateModeInfo() {
        viewModel.trackAnalyticsImportUpdateModeInfoTapped()
        onAnalyticsImportUpdateModeInfoTapped()
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

    func productDetailView(for item: TopEarnerStatsItem) -> UIViewController {
        let loaderViewController = ProductLoaderViewController(model: .init(topEarnerStatsItem: item),
                                                               siteID: viewModel.siteID,
                                                               forceReadOnly: false)
        return WooNavigationController(rootViewController: loaderViewController)
    }
}

private extension StoreTopPerformersDashboardCard {
    enum Constants {
        static let timeRanges: [StatsTimeRangeV4] = [.today, .thisWeek, .thisMonth, .thisYear, .custom(from: .now, to: .now)]
    }

    enum Localization {
        static let hideCard = NSLocalizedString(
            "topPerformersDashboardView.hideCard",
            value: "Hide Top Performers",
            comment: "Menu item to dismiss the Top Performers section on the Dashboard screen"
        )
        static let viewAll = NSLocalizedString(
            "topPerformersDashboardView.viewAll",
            value: "View all store analytics",
            comment: "Button to navigate to Analytics Hub."
        )
        static let custom = NSLocalizedString(
            "topPerformersDashboardView.custom",
            value: "Custom",
            comment: "Title of the custom time range on the Top Performers card on the Dashboard screen"
        )
        static let dateRange = NSLocalizedString("Date Range", comment: "Title of the range selection list")
        static func lastUpdatedText(time: String) -> String {
            let format = NSLocalizedString("Last Updated: %@", comment: "Time for when the top performers card was last updated")
            return String.localizedStringWithFormat(format, time)
        }
        static let scheduledUpdatesDelayText = NSLocalizedString(
            "topPerformersDashboardView.scheduledUpdatesDelayText",
            value: "Stats may be up to 12 hours delayed",
            comment: "Text shown on the Top Performers card instead of the last updated timestamp when analytics updates are scheduled."
        )
        static let unavailableAnalytics = NSLocalizedString(
            "topPerformersDashboardView.unavailableAnalyticsView.title",
            value: "Unable to display your store's top performers",
            comment: "Title when the Top Performers card is disabled because the analytics feature is unavailable"
        )
        static let scheduledUpdatesInfoAccessibilityLabel = NSLocalizedString(
            "topPerformersDashboardView.scheduledUpdatesInfoAccessibilityLabel",
            value: "Analytics update details",
            comment: "Accessibility label for the info button next to the Top Performers card's last updated timestamp."
        )
    }
}

#Preview {
    StoreTopPerformersDashboardCard(
        viewModel: .init(siteID: 123, usageTracksEventEmitter: .init()),
        onViewAllAnalytics: { _, _, _ in },
        onAnalyticsImportUpdateModeInfoTapped: {}
    )
    .padding(StorePadding.p5)
    .background(Color.storeSurfaceDim)
}
