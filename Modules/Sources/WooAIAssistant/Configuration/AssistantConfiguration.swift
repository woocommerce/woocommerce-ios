/// Pinned model + prompt + tool catalog versions plus the upstream feature name.
/// Treat as a release tuple: changing any of the four is a behavior change worth a smoke run.
public enum AssistantConfiguration {
    public static let chatModel = "gpt-4o-mini"
    public static let promptVersion = "v1"
    public static let toolCatalogVersion = "v1"
    /// `feature` parameter the WPCOM jetpack-ai-query proxy stamps on every upstream call;
    /// also the analytics correlation key the eventual telemetry pipeline keys on.
    public static let featureName = "woo-ai-assistant"
}
