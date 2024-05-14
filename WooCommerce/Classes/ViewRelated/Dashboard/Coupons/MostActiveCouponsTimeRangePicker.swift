import SwiftUI
import enum Yosemite.MostActiveCouponsTimeRange

/// View for picking a time range for most active coupons.
///
struct MostActiveCouponsTimeRangePicker: View {
    let timeRanges: [MostActiveCouponsTimeRange] = [.allTime, .custom(from: Date(), to: Date().addingTimeInterval(1)), .thisYear, .thisMonth, .thisWeek, .today]
    let currentTimeRange: MostActiveCouponsTimeRange
    let onSelect: (MostActiveCouponsTimeRange) -> Void

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

    private func isTimeRangeSelected(_ range: MostActiveCouponsTimeRange) -> Bool {
        if range.isCustomTimeRange && currentTimeRange.isCustomTimeRange {
            return true
        }
        return range == currentTimeRange
    }
}

#Preview {
    MostActiveCouponsTimeRangePicker(currentTimeRange: .today, onSelect: { _ in })
}
