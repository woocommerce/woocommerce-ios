import Foundation
import Networking
import Storage


// MARK: - RefundStore
//
public class RefundStore: Store {
    private let remote: RefundsRemote
    private let upserter: RefundsUpserter

    override public init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = RefundsRemote(network: network)
        self.upserter = RefundsUpserter(storageManager: storageManager)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: RefundAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? RefundAction else {
            assertionFailure("RefundStore received an unsupported action")
            return
        }

        switch action {
        case .createRefund(let siteID, let orderID, let refund, let onCompletion):
            createRefund(siteID: siteID, orderID: orderID, refund: refund, onCompletion: onCompletion)
        case .retrieveRefund(let siteID, let orderID, let refundID, let onCompletion):
            retrieveRefund(siteID: siteID, orderID: orderID, refundID: refundID, onCompletion: onCompletion)
        case .retrieveRefunds(let siteID, let orderID, let refundIDs, let deleteStaleRefunds, let onCompletion):
            retrieveRefunds(siteID: siteID, orderID: orderID, refundIDs: refundIDs, deleteStaleRefunds: deleteStaleRefunds, onCompletion: onCompletion)
        case .synchronizeRefunds(let siteID, let orderID, let pageNumber, let pageSize, let onCompletion):
            synchronizeRefunds(siteID: siteID, orderID: orderID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        case .resetStoredRefunds(let onCompletion):
            resetStoredRefunds(onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension RefundStore {

    /// Creates a new Refund.
    ///
    func createRefund(siteID: Int64, orderID: Int64, refund: Refund, onCompletion: @escaping (Refund?, Error?) -> Void) {
        remote.createRefund(for: siteID, by: orderID, refund: refund) { [weak self] refund, error in
            guard let refund else {
                onCompletion(nil, error)
                return
            }

            self?.upserter.upsertStoredRefundsInBackground(siteID: siteID, orderID: orderID, readOnlyRefunds: [refund]) {
                onCompletion(refund, nil)
            }
        }
    }

    /// Retrieves a single Refund by ID.
    ///
    func retrieveRefund(siteID: Int64, orderID: Int64, refundID: Int64, onCompletion: @escaping (Networking.Refund?, Error?) -> Void) {
        remote.loadRefund(siteID: siteID, orderID: orderID, refundID: refundID) { [weak self] refund, error in
            guard let refund else {
                if case NetworkError.notFound? = error {
                    self?.deleteStoredRefund(siteID: siteID, orderID: orderID, refundID: refundID) {
                        onCompletion(nil, error)
                    }
                } else {
                    onCompletion(nil, error)
                }
                return
            }

            self?.upserter.upsertStoredRefundsInBackground(siteID: siteID, orderID: orderID, readOnlyRefunds: [refund]) {
                onCompletion(refund, nil)
            }
        }
    }

    /// Retrieves all Refunds by an orderID.
    ///
    func retrieveRefunds(siteID: Int64, orderID: Int64, refundIDs: [Int64], deleteStaleRefunds: Bool, onCompletion: @escaping (Error?) -> Void) {
        let storedRefunds = storageManager.viewStorage.loadRefunds(siteID: siteID, orderID: orderID)
        let staleRefundIDs: [Int64] = {
            guard deleteStaleRefunds else {
                return []
            }
            return storedRefunds
                .map { $0.refundID }
                .filter { !refundIDs.contains($0) }
        }()

        let missingRefundIDs = refundIDs.filter { refundID in
            !storedRefunds.contains { $0.refundID == refundID }
        }

        // If all refund IDs exist in storage, delete stale items and skip the remote request.
        if missingRefundIDs.isEmpty {
            if deleteStaleRefunds {
                storageManager.performAndSave({ storage in
                    let storedRefunds = storage.loadRefunds(siteID: siteID, orderID: orderID)
                    self.upserter.deleteStaleRefunds(staleRefundIDs: staleRefundIDs,
                                                     storedRefunds: storedRefunds,
                                                     in: storage)
                }, completion: {
                    onCompletion(nil)
                }, on: .main)
            } else {
                onCompletion(nil)
            }
            return
        }

        // Request any refunds that don't exist in storage.
        remote.loadRefunds(for: siteID, by: orderID, with: missingRefundIDs) { [weak self] refunds, error in
            guard let refunds else {
                return onCompletion(error)
            }

            self?.upserter.upsertStoredRefundsInBackground(siteID: siteID,
                                                           orderID: orderID,
                                                           readOnlyRefunds: refunds,
                                                           staleRefundIDs: staleRefundIDs) {
                onCompletion(nil)
            }
        }
    }

    /// Synchronizes the refunds associated with a given orderID
    ///
    func synchronizeRefunds(siteID: Int64, orderID: Int64, pageNumber: Int, pageSize: Int, onCompletion: @escaping (Error?) -> Void) {
        remote.loadAllRefunds(for: siteID, by: orderID) { [weak self] refunds, error in
            guard let refunds else {
                onCompletion(error)
                return
            }

            self?.upserter.upsertStoredRefundsInBackground(siteID: siteID, orderID: orderID, readOnlyRefunds: refunds) {
                onCompletion(nil)
            }
        }
    }

    /// Deletes all of the stored Refunds.
    ///
    func resetStoredRefunds(onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ storage in
            storage.deleteAllObjects(ofType: Storage.Refund.self)
        }, completion: {
            DDLogDebug("Refunds deleted")
            onCompletion()
        }, on: .main)
    }
}


// MARK: - Storage: Refund
//
private extension RefundStore {

    /// Deletes any Storage.Refund with the specified `siteID`, `orderID`, and `refundID`
    ///
    func deleteStoredRefund(siteID: Int64, orderID: Int64, refundID: Int64, onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ storage in
            guard let refund = storage.loadRefund(siteID: siteID, orderID: orderID, refundID: refundID) else {
                return
            }
            storage.deleteObject(refund)
        }, completion: onCompletion, on: .main)
    }
}

// MARK: - Unit Testing Helpers
//
extension RefundStore {

    /// Unit Testing Helper: Updates or Inserts the specified ReadOnly Refund in a given Storage Layer.
    ///
    func upsertStoredRefund(readOnlyRefund: Networking.Refund, in storage: StorageType) {
        let siteID = readOnlyRefund.siteID
        let orderID = readOnlyRefund.orderID
        let storedRefunds = storage.loadRefunds(siteID: siteID, orderID: orderID)
        upserter.upsertStoredRefunds(siteID: siteID,
                                     orderID: orderID,
                                     storedRefunds: storedRefunds,
                                     readOnlyRefunds: [readOnlyRefund],
                                     in: storage)
    }
}
