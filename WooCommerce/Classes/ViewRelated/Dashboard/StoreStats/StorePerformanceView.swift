import SwiftUI

/// View for store performance on Dashboard screen
///
struct StorePerformanceView: View {
    @ObservedObject private var viewModel: StorePerformanceViewModel
    @State private var showingCustomRangePicker = false

    init(viewModel: StorePerformanceViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        if viewModel.statsVersion == .v4 {
            VStack(alignment: .leading) {
                header
                    .padding(.horizontal, Layout.padding)
                    .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                    .shimmering(active: viewModel.syncingData)

                timeRangeBar
                    .padding(.horizontal, Layout.padding)
                    .redacted(reason: viewModel.syncingData ? [.placeholder] : [])
                    .shimmering(active: viewModel.syncingData)

                Divider()

            }
            .padding(.vertical, Layout.padding)
            .background(Color(.listForeground(modal: false)))
            .clipShape(RoundedRectangle(cornerSize: Layout.cornerSize))
            .padding(.horizontal, Layout.padding)
            .sheet(isPresented: $showingCustomRangePicker) {
                RangedDatePicker(startDate: viewModel.startDateForCustomRange,
                                 endDate: viewModel.endDateForCustomRange,
                                 datesFormatter: DatesFormatter(),
                                 customApplyButtonTitle: viewModel.buttonTitleForCustomRange,
                                 datesSelected: { start, end in
                    viewModel.didSelectTimeRange(.custom(from: start, to: end))
                })
            }
        } else {
            ViewControllerContainer(DeprecatedDashboardStatsViewController())
        }
    }
}

private extension StorePerformanceView {
    var header: some View {
        HStack {
            Text(Localization.title)
                .headlineStyle()
            Spacer()
            Menu {
                Button(Localization.hideCard) {
                    // TODO
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(Color.secondary)
                    .padding([.vertical, .leading], Layout.padding)
            }
        }
    }

    var timeRangeBar: some View {
        HStack(alignment: .top) {
            AdaptiveStack(horizontalAlignment: .leading) {
                Text(viewModel.timeRange.tabTitle)
                    .foregroundStyle(Color(.text))
                    .subheadlineStyle()
                Text(viewModel.timeRangeText)
                    .subheadlineStyle()
            }
            Spacer()
            StatsTimeRangePicker(currentTimeRange: viewModel.timeRange) { newTimeRange in
                if newTimeRange.isCustomTimeRange {
                    showingCustomRangePicker = true
                } else {
                    viewModel.didSelectTimeRange(newTimeRange)
                }
            }
        }
    }
}

private extension StorePerformanceView {
    enum Layout {
        static let padding: CGFloat = 16
        static let cornerSize = CGSize(width: 8.0, height: 8.0)
        static let strokeWidth: CGFloat = 0.5
    }

    enum Localization {
        static let title = NSLocalizedString(
            "storePerformanceView.title",
            value: "Performance",
            comment: "Title of the store performance section on the Dashboard screen"
        )
        static let hideCard = NSLocalizedString(
            "storePerformanceView.hideCard",
            value: "Hide this card",
            comment: "Menu item to dismiss the store performance section on the Dashboard screen"
        )
    }

    /// Specific `DatesFormatter` for the `RangedDatePicker` when presented in the analytics hub module.
    ///
    struct DatesFormatter: RangedDateTextFormatter {
        func format(start: Date, end: Date) -> String {
            start.formatAsRange(with: end, timezone: .current, calendar: Locale.current.calendar)
        }
    }
}

#Preview {
    StorePerformanceView(viewModel: StorePerformanceViewModel(siteID: 123))
}
