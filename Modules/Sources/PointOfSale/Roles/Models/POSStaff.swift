/// The operator a PIN unlocks POS as. Permission checks read `capabilities`, not `role`, so a synced
/// staff record can carry its own capabilities.
struct POSStaff: Equatable, Sendable {
    let role: POSRole
    let capabilities: Set<POSCapability>

    init(role: POSRole, capabilities: Set<POSCapability>? = nil) {
        self.role = role
        self.capabilities = capabilities ?? role.capabilities
    }

    func hasCapability(_ capability: POSCapability) -> Bool {
        capabilities.contains(capability)
    }
}
