/// Catalog entry the orchestrator hands to the model so it knows what tools exist.
public struct AITool: Sendable {
    public let name: String
    public let description: String
    public let parametersSchema: AnyCodableJSON

    public init(name: String, description: String, parametersSchema: AnyCodableJSON) {
        self.name = name
        self.description = description
        self.parametersSchema = parametersSchema
    }
}
