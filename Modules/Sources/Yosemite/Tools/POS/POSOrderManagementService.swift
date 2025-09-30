import Foundation
import Networking
import protocol Storage.StorageManagerType
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite

public protocol POSOrderManagementServiceProtocol {
    /// Deletes an order permanently or moves it to trash
    /// - Parameters:
    ///   - siteID: The site ID where the order belongs
    ///   - order: The order to delete
    ///   - deletePermanently: Whether to delete permanently or move to trash
    ///   - onCompletion: Completion handler with the result
    func deleteOrder(siteID: Int64, order: Order, deletePermanently: Bool, onCompletion: @escaping (Result<Order, Error>) -> Void)
}

public final class POSOrderManagementService: POSOrderManagementServiceProtocol {
    private let orderStoreMethods: OrderStoreMethodsProtocol

    public convenience init?(siteID: Int64,
                             credentials: Credentials?,
                             selectedSite: AnyPublisher<JetpackSite?, Never>,
                             appPasswordSupportState: AnyPublisher<Bool, Never>,
                             storageManager: StorageManagerType) {
        guard let credentials else {
            DDLogError("⛔️ Could not create POSOrderManagementService due to not finding credentials")
            return nil
        }
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        let remote = OrdersRemote(network: network)
        self.init(storageManager: storageManager, remote: remote)
    }

    public init(storageManager: StorageManagerType, remote: OrdersRemote) {
        self.orderStoreMethods = OrderStoreMethods(storageManager: storageManager, remote: remote)
    }

    // MARK: - Protocol conformance
    public func deleteOrder(siteID: Int64, order: Order, deletePermanently: Bool, onCompletion: @escaping (Result<Order, Error>) -> Void) {
        orderStoreMethods.deleteOrder(siteID: siteID, order: order, deletePermanently: deletePermanently, onCompletion: onCompletion)
    }
}
