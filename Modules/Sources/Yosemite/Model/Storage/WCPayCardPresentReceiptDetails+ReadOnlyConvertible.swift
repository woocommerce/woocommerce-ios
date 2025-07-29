import Foundation
import Storage

extension Storage.WCPayCardPresentReceiptDetails: ReadOnlyConvertible {
    public func update(with receiptDetails: Yosemite.WCPayCardPresentReceiptDetails) {
        accountType = receiptDetails.accountType.rawValue
        applicationPreferredName = receiptDetails.applicationPreferredName
        dedicatedFileName = receiptDetails.dedicatedFileName
    }

    public func toReadOnly() -> Yosemite.WCPayCardPresentReceiptDetails {
        let yosemiteAccountType = WCPayCardFunding(rawValue: accountType) ?? .unknown
        return WCPayCardPresentReceiptDetails(accountType: yosemiteAccountType,
                                              applicationPreferredName: applicationPreferredName,
                                              dedicatedFileName: dedicatedFileName)
    }
}

// MARK: - Storage.WCPayCardPresentReceiptDetails: ListItemConvertible
//
extension Storage.WCPayCardPresentReceiptDetails: ListItemConvertible {
    public func toListItem() -> Yosemite.WCPayCardPresentReceiptDetails {
        return toReadOnly()
    }
}
