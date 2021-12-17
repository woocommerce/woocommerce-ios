import Foundation
import Networking

/// The view model of the SiteHealthStatusChecker view.
/// Declared as `MainActor` because the update of the `requests` var should be updated on the main thread
///
@MainActor final class SiteHealthStatusCheckerViewModel: ObservableObject {

    private typealias RequestCheckedContinuation = CheckedContinuation<SiteHealthStatusCheckerRequest, Never>
    private typealias RequestCheckedContinuationWithID = CheckedContinuation<(SiteHealthStatusCheckerRequest, Int64?), Never>

    let siteID: Int64
    let network: AlamofireNetwork

    @Published private(set) var isLoading = false
    @Published var requests: [SiteHealthStatusCheckerRequest] = []
    var shouldShowEmptyState: Bool {
        return requests.isEmpty
    }

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
        isLoading = true
        var requests: [SiteHealthStatusCheckerRequest] = []
        requests.append(await fetchOrders())

        let productsRequest = await fetchProducts()
        requests.append(productsRequest.0)

        if let productId = productsRequest.1 {
            requests.append(await fetchSingleProduct(productId: productId))
        }

        isLoading = false
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

    func fetchProducts() async -> (SiteHealthStatusCheckerRequest, Int64?) {
        let startTime = Date()
        let remote = ProductsRemote(network: network)

        return await withCheckedContinuation({
            (continuation: RequestCheckedContinuationWithID) in
            remote.loadAllProducts(for: siteID) { result in
                let timeInterval = Date().timeIntervalSince(startTime)
                let request = SiteHealthStatusCheckerRequest(actionName: "Fetch All Products",
                                                             endpointName: "/products",
                                                             success: result.isSuccess,
                                                             error: result.failure,
                                                             time: timeInterval)
                switch result {
                case .success(let products):
                    continuation.resume(returning: (request, products.randomElement()?.productID))
                    break
                case .failure(_):
                    continuation.resume(returning: (request, nil))
                }
            }
        })
    }

    func fetchSingleProduct(productId: Int64) async -> SiteHealthStatusCheckerRequest {
        let startTime = Date()
        let remote = ProductsRemote(network: network)

        return await withCheckedContinuation({
            (continuation: RequestCheckedContinuation) in
            remote.loadProduct(for: siteID, productID: productId) { result in
                let timeInterval = Date().timeIntervalSince(startTime)
                let request = SiteHealthStatusCheckerRequest(actionName: "Fetch Single Product",
                                                             endpointName: "/products/\(productId)",
                                                             success: result.isSuccess,
                                                             error: result.failure,
                                                             time: timeInterval)
                continuation.resume(returning: request)
            }
        })
    }
}
