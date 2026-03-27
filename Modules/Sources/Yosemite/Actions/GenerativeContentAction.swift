import Networking

/// Defines actions for AI-powered generative content operations.
///
public enum GenerativeContentAction: Action {

    /// Generates text based on the given prompt using Jetpack AI.
    ///
    case generateText(siteID: Int64,
                      base: String,
                      feature: GenerativeContentRemoteFeature,
                      responseFormat: GenerativeContentRemoteResponseFormat,
                      completion: (Result<String, Error>) -> Void)

    /// Identifies the language from the given string.
    ///
    case identifyLanguage(siteID: Int64,
                          string: String,
                          feature: GenerativeContentRemoteFeature,
                          completion: (Result<String, Error>) -> Void)
}
