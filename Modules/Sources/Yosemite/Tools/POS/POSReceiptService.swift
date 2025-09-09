import SwiftUI
import Networking

public protocol POSReceiptServiceProtocol {
    func sendReceipt(orderID: Int64, recipientEmail: String, isEligibleForPOSReceipt: Bool) async throws
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

    public func sendReceipt(orderID: Int64, recipientEmail: String, isEligibleForPOSReceipt: Bool) async throws {
        do {
            if isEligibleForPOSReceipt {
                try await receiptsRemote.sendPOSReceipt(siteID: siteID, orderID: orderID, emailAddress: recipientEmail)
            } else {
                try await receiptsRemote.sendReceipt(siteID: siteID, orderID: orderID)
            }
        } catch {
            throw POSReceiptServiceError.sendReceiptFailed(underlyingError: error as NSError)
        }
    }
}

public extension POSReceiptService {
    enum POSReceiptServiceError: Error {
        case sendReceiptFailed(underlyingError: NSError)
    }
}
