public struct POSReceiptInformation: Equatable {
    public let storeName: String?
    public let storeAddress: String?
    public let phone: String?
    public let email: String?
    public let refundReturnsPolicy: String?

    public init(storeName: String?, storeAddress: String?, phone: String?, email: String?, refundReturnsPolicy: String?) {
        self.storeName = storeName
        self.storeAddress = storeAddress
        self.phone = phone
        self.email = email
        self.refundReturnsPolicy = refundReturnsPolicy
    }

    public static let empty = POSReceiptInformation(
        storeName: nil,
        storeAddress: nil,
        phone: nil,
        email: nil,
        refundReturnsPolicy: nil
    )
}
