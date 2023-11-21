import Foundation
import Yosemite

final class MockWooPaymentsDepositService: WooPaymentsDepositServiceProtocol {
    var onFetchDepositsOverviewThenReturn: [WooPaymentsDepositsOverviewByCurrency] = []
    var spyDidCallFetchDepositsOverview = false
    func fetchDepositsOverview() async -> [WooPaymentsDepositsOverviewByCurrency] {
        spyDidCallFetchDepositsOverview = true
        return onFetchDepositsOverviewThenReturn
    }
}
