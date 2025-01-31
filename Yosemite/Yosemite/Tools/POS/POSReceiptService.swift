import SwiftUI
import Networking

public protocol POSReceiptServiceProtocol {
    func sendReceipt(order: Order, recipientEmail: String) async throws
}

public final class POSReceiptService: POSReceiptServiceProtocol {
    private let siteID: Int64
    private let receiptsRemote: POSReceiptsRemoteProtocol

    public convenience init?(siteID: Int64, credentials: Credentials?) {
        guard let credentials else {
            DDLogError("⛔️ Could not create POSReceiptService due to not finding credentials")
            return nil
        }
        let network = AlamofireNetwork(credentials: credentials)
        self.init(siteID: siteID,
                  receiptsRemote: ReceiptRemote(network: network))
    }

    public init(siteID: Int64,
                receiptsRemote: POSReceiptsRemoteProtocol) {
        self.siteID = siteID
        self.receiptsRemote = receiptsRemote
    }

    public func sendReceipt(order: Yosemite.Order, recipientEmail: String) async throws {
        do {
            try await receiptsRemote.sendReceipt(siteID: siteID, orderID: order.orderID)
        } catch {
            throw POSReceiptServiceError.sendReceiptFailed
        }
    }
}

public extension POSReceiptService {
    enum POSReceiptServiceError: Error {
        case sendReceiptFailed
    }
}
