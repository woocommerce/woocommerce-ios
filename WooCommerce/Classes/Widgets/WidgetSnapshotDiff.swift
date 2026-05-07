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
        Array(currentDateRanges.subtracting(previousDateRanges)).sorted()
    }

    var removedDateRanges: [String] {
        Array(previousDateRanges.subtracting(currentDateRanges)).sorted()
    }

    var addedMetrics: [String] {
        Array(currentMetrics.subtracting(previousMetrics)).sorted()
    }

    var removedMetrics: [String] {
        Array(previousMetrics.subtracting(currentMetrics)).sorted()
    }

    var addedWidgets: [String] {
        Array(currentWidgetNames.subtracting(previousWidgetNames)).sorted()
    }

    var removedWidgets: [String] {
        Array(previousWidgetNames.subtracting(currentWidgetNames)).sorted()
    }

    private var currentDateRanges: Set<String> { current.storeInfoDateRangesInUse }
    private var previousDateRanges: Set<String> { previous.storeInfoDateRangesInUse }
    private var currentMetrics: Set<String> { current.storeInfoMetricsInUse }
    private var previousMetrics: Set<String> { previous.storeInfoMetricsInUse }
    private var currentWidgetNames: Set<String> { Set(current.tiles.map(\.analyticsName)) }
    private var previousWidgetNames: Set<String> { Set(previous.tiles.map(\.analyticsName)) }
}
