/// The operator a PIN unlocks POS as. Permission checks read only `capabilities`, so a synced staff
/// record can carry its own set.
struct POSStaff: Equatable, Sendable {
    let displayName: String
    let capabilities: Set<POSCapability>

    func hasCapability(_ capability: POSCapability) -> Bool {
        capabilities.contains(capability)
    }
}
