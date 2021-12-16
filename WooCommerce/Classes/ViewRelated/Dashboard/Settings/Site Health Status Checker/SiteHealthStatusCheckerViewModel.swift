import Foundation
import Networking

final class SiteHealthStatusCheckerViewModel: ObservableObject {

    private typealias RequestCheckedContinuation = CheckedContinuation<SiteHealthStatusCheckerRequest, Never>

    let siteID: Int64
    let network: AlamofireNetwork

    @Published private var workInProgress = false

    init(siteID: Int64) {
        self.siteID = siteID
        if let credentials = ServiceLocator.stores.sessionManager.defaultCredentials {
            network = AlamofireNetwork(credentials: credentials)
        }
        else {
            network = AlamofireNetwork(credentials: Credentials(authToken: "-"))
        }
    }

    func startChecking() async -> [SiteHealthStatusCheckerRequest] {
        workInProgress = true
        var requests: [SiteHealthStatusCheckerRequest] = []
        requests.append(await fetchOrders())

        workInProgress = false
        return requests
    }
}

// MARK: - API Calls
//
private extension SiteHealthStatusCheckerViewModel {
    func fetchOrders() async -> SiteHealthStatusCheckerRequest {
        let startTime = Date()
        let remote = OrdersRemote(network: network)

        return await withCheckedContinuation({
            (continuation: RequestCheckedContinuation) in
            remote.loadAllOrders(for: siteID) { result in
                let timeInterval = Date().timeIntervalSince(startTime)
                let request = SiteHealthStatusCheckerRequest(endpointName: "orders/fetch",
                                                             actionName: "Fetch All Orders",
                                                             success: result.isSuccess,
                                                             error: result.failure,
                                                             time: timeInterval)
                continuation.resume(returning: request)
            }
        })
    }
}
