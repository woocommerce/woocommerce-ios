struct POSStaff: Equatable, Sendable {
    let userID: Int64
    let userLogin: String
    let displayName: String
    let role: String
    let capabilities: Set<String>

    func hasCapability(_ capability: POSCapability) -> Bool {
        capabilities.contains(capability.rawValue)
    }
}
