import SwiftUI

/// View for store performance on Dashboard screen
///
struct StorePerformanceView: View {
    @ObservedObject private var viewModel: StorePerformanceViewModel

    init(viewModel: StorePerformanceViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading) {
            header
                .padding(.horizontal, Layout.padding)

            timeRangeBar
                .padding(.horizontal, Layout.padding)

            Divider()

        }
        .padding(.vertical, Layout.padding)
        .background(Color(.listForeground(modal: false)))
        .clipShape(RoundedRectangle(cornerSize: Layout.cornerSize))
        .padding(.horizontal, Layout.padding)
    }
}

private extension StorePerformanceView {
    var header: some View {
        HStack(alignment: .top) {
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
            }
        }
    }

    var timeRangeBar: some View {
        HStack(alignment: .top) {
            AdaptiveStack {
                Text(viewModel.timeRange.tabTitle)
                    .subheadlineStyle()
            }
            Spacer()
            StatsTimeRangePicker(currentTimeRange: viewModel.timeRange) { newTimeRange in
                if newTimeRange.isCustomTimeRange {
                    // TODO: show date picker
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
}

#Preview {
    StorePerformanceView(viewModel: StorePerformanceViewModel(siteID: 123))
}
