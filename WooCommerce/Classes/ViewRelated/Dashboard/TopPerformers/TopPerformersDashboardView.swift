import SwiftUI
import enum Yosemite.StatsTimeRangeV4
import struct Yosemite.TopEarnerStatsItem
import struct Yosemite.DashboardCard

/// SwiftUI view for the Top Performers dashboard card.
///
struct TopPerformersDashboardView: View {
    @ObservedObject private var viewModel: TopPerformersDashboardViewModel
    @State private var showingCustomRangePicker = false

    private let onViewAllAnalytics: (_ siteID: Int64,
                                     _ timeZone: TimeZone,
                                     _ timeRange: StatsTimeRangeV4) -> Void

    init(viewModel: TopPerformersDashboardViewModel,
         onViewAllAnalytics: @escaping (Int64, TimeZone, StatsTimeRangeV4) -> Void) {
        self.viewModel = viewModel
        self.onViewAllAnalytics = onViewAllAnalytics
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.padding) {
            header
                .padding(.horizontal, Layout.padding)

            if !viewModel.analyticsEnabled {
                UnavailableAnalyticsView(title: Localization.unavailableAnalytics)
                    .padding(.horizontal, Layout.padding)
            } else if viewModel.syncingError != nil {
                DashboardCardErrorView(onRetry: {
                    ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .topPerformers))
                    Task {
                        await viewModel.reloadDataIfNeeded(forceRefresh: true)
                    }
                })
                .padding(.horizontal, Layout.padding)
            } else {
                timeRangeBar
                    .padding(.horizontal, Layout.padding)
                    .redacted(reason: viewModel.periodViewModel.redacted.header ? [.placeholder] : [])
                    .shimmering(active: viewModel.periodViewModel.redacted.header)

                Divider()

                topPerformersList

                Divider()
                    .padding(.leading, Layout.padding)

                timestampView
                    .renderedIf(viewModel.lastUpdatedTimestamp.isNotEmpty)
                    .redacted(reason: viewModel.periodViewModel.redacted.rows ? [.placeholder] : [])
                    .shimmering(active: viewModel.periodViewModel.redacted.rows)

                viewAllAnalyticsButton
                    .padding(.horizontal, Layout.padding)
                    .redacted(reason: viewModel.periodViewModel.redacted.actionButton ? [.placeholder] : [])
                    .shimmering(active: viewModel.periodViewModel.redacted.actionButton)
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
        .sheet(item: $viewModel.selectedItem) { item in
            ViewControllerContainer(productDetailView(for: item))
        }
        .onAppear {
            viewModel.onViewAppear()
        }
    }
}

private extension TopPerformersDashboardView {
    var header: some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(Color.secondary)
                .headlineStyle()
                .renderedIf(viewModel.syncingError != nil)
            Text(DashboardCard.CardType.topPerformers.name)
                .headlineStyle()
            Spacer()
            Menu {
                Button(Localization.hideCard) {
                    viewModel.dismissTopPerformers()
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

    var topPerformersList: some View {
        TopPerformersPeriodView(viewModel: viewModel.periodViewModel)
            .frame(maxWidth: .infinity)
    }

    var timestampView: some View {
        Text(Localization.lastUpdatedText(time: viewModel.lastUpdatedTimestamp))
            .footnoteStyle()
            .frame(maxWidth: .infinity, alignment: .center)
    }

    func productDetailView(for item: TopEarnerStatsItem) -> UIViewController {
        let loaderViewController = ProductLoaderViewController(model: .init(topEarnerStatsItem: item),
                                                               siteID: viewModel.siteID,
                                                               forceReadOnly: false)
        return WooNavigationController(rootViewController: loaderViewController)
    }
}

private extension TopPerformersDashboardView {
    enum Layout {
        static let padding: CGFloat = 16
        static let cornerSize = CGSize(width: 8.0, height: 8.0)
        static let hideIconVerticalPadding: CGFloat = 8
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
        static func lastUpdatedText(time: String) -> String {
            let format = NSLocalizedString("Last Updated: %@", comment: "Time for when the top performers card was last updated")
            return String.localizedStringWithFormat(format, time)
        }
        static let unavailableAnalytics = NSLocalizedString(
            "topPerformersDashboardView.unavailableAnalyticsView.title",
            value: "Unable to display your store's top performers",
            comment: "Title when the Top Performers card is disabled because the analytics feature is unavailable"
        )
    }
}

#Preview {
    TopPerformersDashboardView(viewModel: .init(siteID: 123, usageTracksEventEmitter: .init()),
                               onViewAllAnalytics: { _, _, _ in })
}
