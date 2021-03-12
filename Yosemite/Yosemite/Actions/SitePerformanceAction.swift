import Foundation
import Networking

// MARK: - SitePerformanceAction: Defines all of the Actions supported by the SitePerformanceStore.
//
public enum SitePerformanceAction: Action {
    case fetchResponseTimes(onCompletion: ([Int]) -> Void)
}
