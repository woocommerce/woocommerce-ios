import Foundation
import Yosemite

final class MockWooPaymentsDepositService: WooPaymentsDepositServiceProtocol {
    var onFetchDepositsOverviewThenReturn: [WooPaymentsDepositsOverviewByCurrency] = []
    var onFetchDepositsOverviewShouldThrow: Error? = nil
    var spyDidCallFetchDepositsOverview = false
    func fetchDepositsOverview() async throws -> [WooPaymentsDepositsOverviewByCurrency] {
        spyDidCallFetchDepositsOverview = true
        if let error = onFetchDepositsOverviewShouldThrow {
            throw error
        } else {
            return onFetchDepositsOverviewThenReturn
        }
    }
}
