import Foundation
import Networking
import protocol Storage.StorageManagerType

/// Handles `PaymentAction`
///
public final class PaymentStore: Store {
    // Keeps a strong reference to remote to keep requests alive.
    private let remote: PaymentRemoteProtocol

    public init(remote: PaymentRemoteProtocol,
                dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                network: Network) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    public convenience override init(dispatcher: Dispatcher,
                                     storageManager: StorageManagerType,
                                     network: Network) {
        let remote = PaymentRemote(network: network)
        self.init(remote: remote,
                  dispatcher: dispatcher,
                  storageManager: storageManager,
                  network: network)
    }

    public override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: PaymentAction.self)
    }

    /// Called whenever a given Action is dispatched.
    ///
    public override func onAction(_ action: Action) {
        guard let action = action as? PaymentAction else {
            assertionFailure("PaymentStore received an unsupported action: \(action)")
            return
        }
        switch action {
        case .loadPlan(let productID, let completion):
            loadPlan(productID: productID, completion: completion)
        case .createCart(let productID, let siteID, let completion):
            createCart(productID: productID, siteID: siteID, completion: completion)
        }
    }
}

private extension PaymentStore {
    func loadPlan(productID: Int64,
                  completion: @escaping (Result<WPComPlan, Error>) -> Void) {
        Task { @MainActor in
            do {
                let plan = try await remote.loadPlan(thatMatchesID: productID)
                completion(.success(plan))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func createCart(productID: String,
                    siteID: Int64,
                    completion: @escaping (Result<Void, Error>) -> Void) {
        Task { @MainActor in
            do {
                guard let productID = Int64(productID) else {
                    return completion(.failure(CreateCartError.invalidProductID))
                }
                _ = try await remote.createCart(siteID: siteID, productID: productID)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

/// Possible cart creation errors.
public enum CreateCartError: Error, Equatable {
    /// Product ID is not in the correct format for WPCOM plans.
    case invalidProductID
}
