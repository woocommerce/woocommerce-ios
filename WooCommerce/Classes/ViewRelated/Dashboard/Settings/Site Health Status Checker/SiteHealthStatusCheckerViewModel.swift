import Foundation
import Networking

/// The view model of the SiteHealthStatusChecker view.
/// Declared as `MainActor` because the update of the requests var should be run on the main thread
///
@MainActor final class SiteHealthStatusCheckerViewModel: ObservableObject {

    private typealias RequestCheckedContinuation = CheckedContinuation<SiteHealthStatusCheckerRequest, Never>

    let siteID: Int64
    let network: AlamofireNetwork

    @Published var workInProgress = false
    @Published var requests: [SiteHealthStatusCheckerRequest] = []

    init(siteID: Int64) {
        self.siteID = siteID
        if let credentials = ServiceLocator.stores.sessionManager.defaultCredentials {
            network = AlamofireNetwork(credentials: credentials)
        }
        else {
            network = AlamofireNetwork(credentials: Credentials(authToken: "-"))
        }
    }

    func startChecking() async {
        requests = await fire()
    }

    private func fire() async -> [SiteHealthStatusCheckerRequest] {
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
                let request = SiteHealthStatusCheckerRequest(actionName: "Fetch All Orders",
                                                             endpointName: "/orders",
                                                             success: result.isSuccess,
                                                             error: result.failure,
                                                             time: timeInterval)
                continuation.resume(returning: request)
            }
        })
    }
}
