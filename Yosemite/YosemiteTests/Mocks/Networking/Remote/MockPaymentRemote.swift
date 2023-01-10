import Networking
import XCTest

/// Mock for `PaymentRemote`.
///
final class MockPaymentRemote {
    /// The results to return in `loadPlan`.
    private var loadPlanResult: Result<WPComPlan, Error>?

    /// The results to return in `createCart`.
    private var createCartResult: Result<Void, Error>?

    /// Returns the value when `loadPlan` is called.
    func whenLoadingPlan(thenReturn result: Result<WPComPlan, Error>) {
        loadPlanResult = result
    }

    /// Returns the value when `createCart` is called.
    func whenCreatingCart(thenReturn result: Result<Void, Error>) {
        createCartResult = result
    }
}

extension MockPaymentRemote: PaymentRemoteProtocol {
    func loadPlan(thatMatchesID productID: Int64) async throws -> Networking.WPComPlan {
        guard let result = loadPlanResult else {
            XCTFail("Could not find result for loading a plan.")
            throw NetworkError.notFound
        }
        return try result.get()
    }

    func loadSiteCurrentPlan(siteID: Int64) async throws -> WPComSitePlan {
        // TODO: 8558 - Yosemite layer
        throw NetworkError.notFound
    }

    func createCart(siteID: Int64, productID: Int64) async throws {
        guard let result = createCartResult else {
            XCTFail("Could not find result for creating a cart.")
            throw NetworkError.notFound
        }
        return try result.get()
    }
}
