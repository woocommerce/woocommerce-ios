/// Pinned model + prompt + tool catalog versions. Treat as a release tuple:
/// changing any of the three is a behavior change worth a smoke run.
public enum AssistantConfiguration {
    public static let chatModel = "gpt-4o-mini"
    public static let promptVersion = "v1"
    public static let toolCatalogVersion = "v1"
}
