public struct POSCoupon: Equatable, Hashable {
    public let id: UUID
    public let code: String
    public let summary: String

    public init(id: UUID, code: String, summary: String = "") {
        self.id = id
        self.code = code
        self.summary = summary
    }
}
