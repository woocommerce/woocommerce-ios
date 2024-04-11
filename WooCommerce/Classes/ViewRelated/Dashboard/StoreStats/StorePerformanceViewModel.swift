import Foundation
import Yosemite

/// View model for `StorePerformanceView`.
///
final class StorePerformanceViewModel: ObservableObject {
    @Published private(set) var timeRange = StatsTimeRangeV4.today
}
