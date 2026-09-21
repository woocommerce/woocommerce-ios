import Foundation

struct WidgetSnapshotDiff: Equatable {
    let previous: WidgetSnapshot
    let current: WidgetSnapshot

    enum ChangeType: String {
        case add = "add"
        case remove = "remove"
        case churn
    }

    var hasChanged: Bool {
        previous != current
    }

    var changeType: ChangeType {
        if current.tiles.count > previous.tiles.count {
            return .add
        }
        if current.tiles.count < previous.tiles.count {
            return .remove
        }
        return .churn
    }

    var addedDateRanges: [String] {
        currentDateRanges.multisetDifference(from: previousDateRanges).sorted()
    }

    var removedDateRanges: [String] {
        previousDateRanges.multisetDifference(from: currentDateRanges).sorted()
    }

    var addedMetrics: [String] {
        currentMetrics.multisetDifference(from: previousMetrics).sorted()
    }

    var removedMetrics: [String] {
        previousMetrics.multisetDifference(from: currentMetrics).sorted()
    }

    var addedWidgets: [String] {
        currentWidgetNames.multisetDifference(from: previousWidgetNames).sorted()
    }

    var removedWidgets: [String] {
        previousWidgetNames.multisetDifference(from: currentWidgetNames).sorted()
    }

    private var currentDateRanges: [String] { current.storeInfoDateRangesInUse }
    private var previousDateRanges: [String] { previous.storeInfoDateRangesInUse }
    private var currentMetrics: [String] { current.storeInfoMetricsInUse }
    private var previousMetrics: [String] { previous.storeInfoMetricsInUse }
    private var currentWidgetNames: [String] { current.tiles.map(\.analyticsName) }
    private var previousWidgetNames: [String] { previous.tiles.map(\.analyticsName) }
}

private extension Array where Element: Hashable {
    /// Returns the multiset difference `self - other`: each occurrence in `other` cancels one
    /// occurrence in `self`, preserving the remaining duplicates and their original order.
    func multisetDifference(from other: [Element]) -> [Element] {
        var counts: [Element: Int] = [:]
        for value in other {
            counts[value, default: 0] += 1
        }
        return reduce(into: []) { result, value in
            if let remaining = counts[value], remaining > 0 {
                counts[value] = remaining - 1
            } else {
                result.append(value)
            }
        }
    }
}
