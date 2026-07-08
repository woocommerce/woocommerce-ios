import enum Yosemite.POSStaffPreset

struct POSStaff: Equatable, Sendable {
    let userID: Int64
    let displayName: String
    let preset: POSStaffPreset
    let capabilities: Set<String>

    func hasCapability(_ capability: POSCapability) -> Bool {
        capabilities.contains(capability.rawValue)
    }
}
