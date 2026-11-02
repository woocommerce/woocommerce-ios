import StoreDesignSystem
import SwiftUI
import enum Yosemite.StatsTimeRangeV4
import struct Yosemite.DashboardCard
import struct Yosemite.TopEarnerStatsItem

struct StoreTopPerformersDashboardCard: View {
    @ObservedObject private var viewModel: TopPerformersDashboardViewModel
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
            StoreDashboardDateRangeHeader(
                timeRange: viewModel.timeRange,
                dateText: viewModel.timeRangeText,
                isDisabled: viewModel.syncingData,
                accessibilityPrefix: "top-performers",
                onSelect: selectTimeRange,
                onEditCustom: editCustomRange
            )
            .padding(.horizontal, StorePadding.p5)
            .redacted(reason: viewModel.periodViewModel.redacted.header ? .placeholder : [])
            .shimmering(active: viewModel.periodViewModel.redacted.header)
            StoreDivider()
                .padding(.bottom, StorePadding.p5)
            StoreTopPerformersPeriodView(viewModel: viewModel.periodViewModel)
            StoreDashboardTimestamp(
                lastUpdatedTimestamp: viewModel.lastUpdatedTimestamp,
                showsScheduledUpdatesDelay: viewModel.shouldShowScheduledAnalyticsImportInfo,
                showsInfoButton: viewModel.shouldShowAnalyticsImportUpdateModeInfoButton,
                onInfoTapped: showAnalyticsImportUpdateModeInfo
            )
            .renderedIf(viewModel.lastUpdatedTimestamp.isNotEmpty)
            StoreDashboardCardFooterAction(Localization.viewAll, isDisabled: viewModel.syncingData) {
                viewModel.trackInteraction()
                onViewAllAnalytics(viewModel.siteID, viewModel.siteTimezone, viewModel.timeRange)
            }
            .redacted(reason: viewModel.periodViewModel.redacted.actionButton ? .placeholder : [])
            .shimmering(active: viewModel.periodViewModel.redacted.actionButton)
        }
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

    func productDetailView(for item: TopEarnerStatsItem) -> UIViewController {
        let loaderViewController = ProductLoaderViewController(model: .init(topEarnerStatsItem: item),
                                                               siteID: viewModel.siteID,
                                                               forceReadOnly: false)
        return WooNavigationController(rootViewController: loaderViewController)
    }
}

private extension StoreTopPerformersDashboardCard {
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
        static let unavailableAnalytics = NSLocalizedString(
            "topPerformersDashboardView.unavailableAnalyticsView.title",
            value: "Unable to display your store's top performers",
            comment: "Title when the Top Performers card is disabled because the analytics feature is unavailable"
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
