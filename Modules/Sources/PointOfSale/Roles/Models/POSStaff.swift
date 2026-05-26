struct POSStaff: Equatable, Sendable {
    let displayName: String
    let role: String
    let capabilities: Set<String>

    func hasCapability(_ capability: POSCapability) -> Bool {
        capabilities.contains(capability.rawValue)
    }
}
