// Pinned release identity. Changing chatModel, promptVersion, or toolCatalogVersion
// is a behavior change worth a smoke run; featureName is the proxy routing slug.
public enum AssistantConfiguration {
    public static let chatModel = "gpt-4o-mini"
    public static let promptVersion = "v1"
    public static let toolCatalogVersion = "v1"
    public static let featureName = "woo-ai-assistant"
    public static let historyWindowSize = 20
}
