import SwiftUI
import Networking
import struct Combine.AnyPublisher

public protocol POSReceiptServiceProtocol {
    func sendReceipt(orderID: Int64, recipientEmail: String, isEligibleForPOSReceipt: Bool, templateID: String?) async throws
}

public final class POSReceiptService: POSReceiptServiceProtocol {
    private let siteID: Int64
    private let receiptsRemote: POSReceiptsRemoteProtocol

    public convenience init?(siteID: Int64,
                             credentials: Credentials?,
                             selectedSite: AnyPublisher<JetpackSite?, Never>,
                             appPasswordSupportState: AnyPublisher<Bool, Never>) {
        guard let credentials else {
            DDLogError("⛔️ Could not create POSReceiptService due to not finding credentials")
            return nil
        }
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        self.init(siteID: siteID,
                  receiptsRemote: ReceiptRemote(network: network))
    }

    public init(siteID: Int64,
                receiptsRemote: POSReceiptsRemoteProtocol) {
        self.siteID = siteID
        self.receiptsRemote = receiptsRemote
    }

    public func sendReceipt(orderID: Int64, recipientEmail: String, isEligibleForPOSReceipt: Bool, templateID: String?) async throws {
        do {
            if isEligibleForPOSReceipt {
                try await receiptsRemote.sendPOSReceipt(siteID: siteID, orderID: orderID, emailAddress: recipientEmail, templateID: templateID)
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
