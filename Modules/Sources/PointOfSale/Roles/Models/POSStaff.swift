struct POSStaff: Equatable, Sendable {
    let userID: Int64
    let displayName: String
    let preset: String
    let capabilities: Set<String>

    func hasCapability(_ capability: POSCapability) -> Bool {
        capabilities.contains(capability.rawValue)
    }
}
