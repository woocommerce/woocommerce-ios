import SwiftUI
import enum Yosemite.StatsTimeRangeV4

/// View for store performance on Dashboard screen
///
struct StorePerformanceView: View {
    @ObservedObject private var viewModel: StorePerformanceViewModel

    let timeRanges: [StatsTimeRangeV4] = [.custom(from: Date(), to: Date().addingTimeInterval(1)), .thisYear, .thisMonth, .thisWeek, .today]

    init(viewModel: StorePerformanceViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading) {
            header
            timeRangeBar
        }
        .padding(Layout.padding)
        .overlay {
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(uiColor: .separator), lineWidth: Layout.strokeWidth)
        }
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
            Text(viewModel.timeRange.tabTitle)
                .subheadlineStyle()
            Spacer()
            Menu {
                ForEach(timeRanges, id: \.rawValue) { range in
                    Button {
                        // TODO
                    } label: {
                        SelectableItemRow(title: range.tabTitle, selected: isTimeRangeSelected(range))
                    }
                }
            } label: {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    func isTimeRangeSelected(_ range: StatsTimeRangeV4) -> Bool {
        if range.isCustomTimeRange && viewModel.timeRange.isCustomTimeRange {
            return true
        }
        return range == viewModel.timeRange
    }
}

private extension StorePerformanceView {
    enum Layout {
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 8
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
    StorePerformanceView(viewModel: StorePerformanceViewModel())
}
