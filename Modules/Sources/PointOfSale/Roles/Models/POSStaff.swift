public struct POSStaff: Equatable, Sendable {
    public let displayName: String
    public let role: String
    public let capabilities: Set<String>

    public init(displayName: String, role: String, capabilities: Set<String>) {
        self.displayName = displayName
        self.role = role
        self.capabilities = capabilities
    }

    public func hasCapability(_ capability: POSCapability) -> Bool {
        capabilities.contains(capability.rawValue)
    }
}
