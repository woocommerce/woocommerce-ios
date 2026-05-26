/// Catalog entry the orchestrator hands to the model so it knows what tools exist.
public struct AITool: Sendable {
    public let name: String
    public let description: String
    public let parametersSchema: AnyCodableJSON
    public let safetyLevel: AIToolSafetyLevel

    public init(name: String,
                description: String,
                parametersSchema: AnyCodableJSON,
                safetyLevel: AIToolSafetyLevel) {
        self.name = name
        self.description = description
        self.parametersSchema = parametersSchema
        self.safetyLevel = safetyLevel
    }
}

/// Cross-platform-aligned with the Android client; richer taxonomies were
/// considered and rejected to keep the merchant-facing contract uniform.
public enum AIToolSafetyLevel: Equatable, Sendable {
    /// Side-effect-free or render-only.
    case safe

    /// Mutates store data.
    case unsafe
}
