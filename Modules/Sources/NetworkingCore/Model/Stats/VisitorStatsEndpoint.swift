/// Visitor stats endpoint available for a site and authentication context.
///
public enum VisitorStatsEndpoint: String, Codable, Equatable, Sendable {
    case wpComSummary
    case jetpackStatsApp
    case unavailable

    /// Resolves the visitor stats endpoint from site facts and the current credentials.
    ///
    public static func resolve(site: Site, credentials: Credentials) -> Self {
        switch credentials {
        case .wpcom:
            return .wpComSummary
        case .wporg, .applicationPassword:
            let hasFullJetpack = site.isJetpackConnected
                && site.isJetpackThePluginInstalled
                && !site.isWordPressComStore
            return hasFullJetpack ? .jetpackStatsApp : .unavailable
        }
    }

    /// Resolves the endpoint when site facts are not available.
    ///
    public static func resolve(credentials: Credentials) -> Self {
        switch credentials {
        case .wpcom:
            return .wpComSummary
        case .wporg, .applicationPassword:
            return .unavailable
        }
    }
}
