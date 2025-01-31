import Foundation
import Yosemite

final class MockWooPaymentsPayoutService: WooPaymentsPayoutServiceProtocol {
    var onFetchPayoutsOverviewThenReturn: [WooPaymentsPayoutsOverviewByCurrency] = []
    var onFetchPayoutsOverviewShouldThrow: Error? = nil
    var spyDidCallFetchPayoutsOverview = false
    func fetchPayoutsOverview() async throws -> [WooPaymentsPayoutsOverviewByCurrency] {
        spyDidCallFetchPayoutsOverview = true
        if let error = onFetchPayoutsOverviewShouldThrow {
            throw error
        } else {
            return onFetchPayoutsOverviewThenReturn
        }
    }
}
