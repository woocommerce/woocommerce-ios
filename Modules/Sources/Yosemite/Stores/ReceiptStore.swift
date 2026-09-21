import Foundation
import Storage
import Networking


// MARK: - ReceiptStore
//
public class ReceiptStore: Store {
    private let remote: ReceiptRemote

    override public init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = ReceiptRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: ReceiptAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? ReceiptAction else {
            assertionFailure("ReceiptStore received an unsupported action")
            return
        }

        switch action {
        case .retrieveReceipt(order: let order, onCompletion: let onCompletion):
            retrieveReceipt(order: order, onCompletion: onCompletion)
        case let .sendReceipt(order, email, onCompletion):
            sendReceipt(order: order, email: email, onCompletion: onCompletion)
        }
    }
}


private extension ReceiptStore {
    func retrieveReceipt(order: Order, onCompletion: @escaping (Result<Receipt, Error>) -> Void) {
        remote.retrieveReceipt(siteID: order.siteID,
                               orderID: order.orderID) { result in
            switch result {
            case let .success(receipt):
                onCompletion(.success(receipt))
            case let .failure(error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Sends the receipt for the order to the provided email address if customer email hasn't been set yet.
    /// Updates the billing address of the order to the provided email address and triggers the sending of the receipt.
    /// - Parameters:
    ///  - order: The order for which the receipt is being sent.
    ///  - email: The email address to which the receipt is being sent.
    ///  - onCompletion: The completion block to call when the operation is complete.
    ///
    func sendReceipt(order: Order, email: String, onCompletion: @escaping (Result<Order, Error>) -> Void) {
        guard order.billingAddress?.email == nil || order.billingAddress?.email?.isEmpty == true else {
            onCompletion(.failure(ReceiptStoreError.customerEmailAlreadySet))
            return
        }

        let updatedBillingAddress = order.billingAddress?.copy(email: email) ?? Address(firstName: "",
                                                                                        lastName: "",
                                                                                        company: nil,
                                                                                        address1: "",
                                                                                        address2: nil,
                                                                                        city: "",
                                                                                        state: "",
                                                                                        postcode: "",
                                                                                        country: "",
                                                                                        phone: nil,
                                                                                        email: email)
        let orderToUpdate = order.copy(billingAddress: updatedBillingAddress)

        let action = OrderAction.updateOrder(siteID: order.siteID, order: orderToUpdate, giftCard: nil, fields: [.billingAddress]) { result in
            switch result {
            case let .success(updatedOrder):
                Task { [weak self] in
                    guard let self else {
                        onCompletion(.failure(ReceiptStoreError.storeDeallocated))
                        return
                    }

                    do {
                        try await remote.sendReceipt(siteID: order.siteID, orderID: order.orderID)
                        onCompletion(.success(updatedOrder))
                    } catch {
                        onCompletion(.failure(error))
                    }
                }
            case let .failure(error):
                onCompletion(.failure(error))
            }
        }

        dispatcher.dispatch(action)
    }
}

public enum ReceiptStoreError: Error {
    /// Store has been unexpectedly deallocated
    case storeDeallocated

    /// Customer email has already been set and receipt cannot be sent
    case customerEmailAlreadySet
}
