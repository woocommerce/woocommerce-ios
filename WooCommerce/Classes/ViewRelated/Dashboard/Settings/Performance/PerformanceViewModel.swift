import Foundation
import Yosemite

final class PerformanceViewModel {
    public var responseTimes = [Int]()

    init() {
        let action = SitePerformanceAction.fetchResponseTimes { [weak self] result in
            self?.receiveResponseTimes(responseTimes: result)
        }
        ServiceLocator.stores.dispatch(action)
    }

    func receiveResponseTimes(responseTimes: [Int]) {
        self.responseTimes = responseTimes
    }

    func resetStatistics() {
    }
}
