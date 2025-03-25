public struct POSCoupon: Equatable, Hashable {
    public let id: UUID
    public let code: String

    public init(id: UUID, code: String) {
        self.id = id
        self.code = code
    }
}
