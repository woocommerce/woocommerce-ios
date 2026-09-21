/// Store details printed on a receipt header/footer.
///
/// Hardware-domain mirror of the app's store receipt information, so the printer renderer
/// can include store contact details without importing higher layers.
public struct ReceiptStoreInformation: Equatable {
    public let storeName: String?
    public let storeAddress: String?
    public let phone: String?
    public let email: String?
    public let refundReturnsPolicy: String?

    public init(storeName: String?,
                storeAddress: String?,
                phone: String?,
                email: String?,
                refundReturnsPolicy: String?) {
        self.storeName = storeName
        self.storeAddress = storeAddress
        self.phone = phone
        self.email = email
        self.refundReturnsPolicy = refundReturnsPolicy
    }

    public static let empty = ReceiptStoreInformation(
        storeName: nil,
        storeAddress: nil,
        phone: nil,
        email: nil,
        refundReturnsPolicy: nil
    )
}
