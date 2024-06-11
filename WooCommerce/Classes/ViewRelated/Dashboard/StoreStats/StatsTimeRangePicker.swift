import SwiftUI
import enum Yosemite.StatsTimeRangeV4

/// View for picking a time range for store stats.
///
struct StatsTimeRangePicker: View {
    let timeRanges: [StatsTimeRangeV4] = [.custom(from: Date(), to: Date().addingTimeInterval(1)), .thisYear, .thisMonth, .thisWeek, .today]
    let currentTimeRange: StatsTimeRangeV4
    let onSelect: (StatsTimeRangeV4) -> Void

    var body: some View {
        Menu {
            ForEach(timeRanges.reversed(), id: \.rawValue) { range in
                Button {
                    onSelect(range)
                } label: {
                    SelectableItemRow(title: range.tabTitle, selected: isTimeRangeSelected(range))
                }
            }
        } label: {
            Image(systemName: "calendar")
                .foregroundStyle(Color.secondary)
        }
    }

    private func isTimeRangeSelected(_ range: StatsTimeRangeV4) -> Bool {
        if range.isCustomTimeRange && currentTimeRange.isCustomTimeRange {
            return true
        }
        return range == currentTimeRange
    }
}

#Preview {
    StatsTimeRangePicker(currentTimeRange: .today, onSelect: { _ in })
}
