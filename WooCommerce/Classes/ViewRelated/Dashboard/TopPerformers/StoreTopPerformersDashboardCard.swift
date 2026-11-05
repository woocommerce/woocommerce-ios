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
                customTitle: Localization.custom,
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
                text: timestampText,
                showsInfoButton: viewModel.shouldShowAnalyticsImportUpdateModeInfoButton,
                infoAccessibilityLabel: Localization.scheduledUpdatesInfoAccessibilityLabel,
                onInfoTapped: showAnalyticsImportUpdateModeInfo
            )
            .padding(StorePadding.p5)
            .renderedIf(viewModel.lastUpdatedTimestamp.isNotEmpty)
            .redacted(reason: viewModel.periodViewModel.redacted.rows ? .placeholder : [])
            .shimmering(active: viewModel.periodViewModel.redacted.rows)
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

    func productDetailView(for item: TopEarnerStatsItem) -> UIViewController {
        let loaderViewController = ProductLoaderViewController(model: .init(topEarnerStatsItem: item),
                                                               siteID: viewModel.siteID,
                                                               forceReadOnly: false)
        return WooNavigationController(rootViewController: loaderViewController)
    }
}

private extension StoreTopPerformersDashboardCard {
    typealias Localization = TopPerformersDashboardView.Localization
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
